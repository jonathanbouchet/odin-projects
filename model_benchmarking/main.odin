#+feature dynamic-literals
package main

import "core:os"
import "core:mem"
import "core:fmt"
import "core:encoding/json"
import imgui "../../../ODIN_REPO/external_packages/odin-imgui-main"
import rlimgui "../../../ODIN_REPO/external_packages/backend/rlimgui"
import rl "vendor:raylib"

show_memory :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer {
        for _, entry in track.allocation_map {
            fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
        }
        for entry in track.bad_free_array {
            fmt.eprintf("%v bad free\n", entry.location)
        }
        mem.tracking_allocator_destroy(&track)
    }
}

update_shader_values :: proc(
    light_direction: ^[3]f32, 
    light_color: ^[3]f32, 
    ambient_color: ^[3]f32,
    light_direction_loc: int, 
    light_color_loc: int, 
    ambient_color_loc: int,
    shader: rl.Shader) {
    rl.SetShaderValue(
        shader,
        light_direction_loc,
        light_direction,
        rl.ShaderUniformDataType.VEC3,
    )
    rl.SetShaderValue(
        shader,
        light_color_loc,
        light_color,
        rl.ShaderUniformDataType.VEC3,
    )
    rl.SetShaderValue(
        shader,
        ambient_color_loc,
        ambient_color,
        rl.ShaderUniformDataType.VEC3,
    )
}

draw_models :: proc(positions: []rl.Vector3, sizes: []rl.Vector3, model: rl.Model) {
    for item in soa_zip(pos=positions, size=sizes) {
        // fmt.printfln("pos: %v, size: %v", item.pos, item.size)
        rl.DrawModelEx(model, item.pos, rl.Vector3{0.0, 0.0, 0.0}, 0.0, item.size, rl.RAYWHITE)
    }
}

Settings_Data :: struct {
    positions: []rl.Vector3,
    sizes: []rl.Vector3,
}

main :: proc() {
    // show_memory()
    // Track allocations made through context.allocator.
    tracking: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking, context.allocator)

    // Any allocation using context.allocator is now tracked.
    context.allocator = mem.tracking_allocator(&tracking)

    defer {
        fmt.println("Memory statistics:")
        fmt.printfln("  Current:   %d bytes", tracking.current_memory_allocated)
        fmt.printfln("  Peak:      %d bytes", tracking.peak_memory_allocated)
        fmt.printfln("  Allocated: %d bytes total", tracking.total_memory_allocated)
        fmt.printfln("  Freed:     %d bytes total", tracking.total_memory_freed)
        fmt.printfln("  Allocations: %d", tracking.total_allocation_count)
        fmt.printfln("  Frees:       %d", tracking.total_free_count)

        if len(tracking.allocation_map) > 0 {
            fmt.eprintf("\nUnfreed allocations: %d\n", len(tracking.allocation_map))

            for _, entry in tracking.allocation_map {
                fmt.eprintf(
                    "  %d bytes allocated at %v\n",
                    entry.size,
                    entry.location,
                )
            }
        }

        if len(tracking.bad_free_array) > 0 {
            fmt.eprintf(
                "\nIncorrect frees: %d\n",
                len(tracking.bad_free_array),
            )

            for entry in tracking.bad_free_array {
                fmt.eprintf(
                    "  %p freed at %v\n",
                    entry.memory,
                    entry.location,
                )
            }
        }

        mem.tracking_allocator_destroy(&tracking)
    }
    // 1. Initialize Window
    SCREEN_WIDTH  :: 800
    SCREEN_HEIGHT :: 800
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Raylib 3D Camera Mouse Control")
    defer rl.CloseWindow()

    before_file := tracking.current_memory_allocated
    file_data, ok := os.read_entire_file("settings.json", context.allocator)
    if ok != nil {
        fmt.eprintln("Failed to read file.")
        return
	}
    after_file := tracking.current_memory_allocated

	data: Settings_Data
	err := json.unmarshal(file_data, &data)
	if err != nil {
		fmt.eprintln("Parsing error:", err)
		return
	}
    after_parse := tracking.current_memory_allocated
    fmt.printfln(
        "File buffer retained: %d bytes",
        after_file - before_file,
    )

    fmt.printfln(
        "File buffer + decoded JSON retained: %d bytes",
        after_parse - before_file,
    )
    defer delete(file_data)
	defer delete(data.sizes)
	defer delete(data.positions)

    after_cleanup := tracking.current_memory_allocated

    fmt.printfln(
        "Retained after JSON cleanup: %d bytes",
        after_cleanup - before_file,
    )

	fmt.println("Successfully read keys!")
    for it in soa_zip(p=data.positions, s=data.sizes){
        fmt.printfln("pos: %v, scaling:%v", it.p, it.s)
    }
	// for pos, i in data.positions {
	// 	size := data.sizes[i]
	// 	fmt.printf("Index %d -> Position: %v, Size: %v\n", i, pos, size)
	// }

    camera := rl.Camera3D {
        position   = { 0.0, 10.0, 10.0 },
        target     = { 0.0, 0.0, 0.0 },
        up         = { 0.0, 1.0, 0.0 },
        fovy       = 60.0,
        projection = .PERSPECTIVE,
    }

    rl.SetTargetFPS(60)

    model := rl.LoadModel("assets/building_A.gltf") // <- works, Load model
    defer rl.UnloadModel(model)

    shader := rl.LoadShader("basic.vs", "basic.fs")
    for i in 0..<int(model.materialCount){
        model.materials[i].shader = shader
    }
    defer rl.UnloadShader(shader)

    light_direction := rl.Vector3{-1.0, -1.0, -1.0}
    light_color := rl.Vector3{0.7, 0.7, 0.7}
    ambient_color := rl.Vector3{0.25, 0.25, 0.25}

    light_direction_loc := rl.GetShaderLocation(shader, "lightDirection")
    light_color_loc := rl.GetShaderLocation(shader, "lightColor")
    ambient_color_loc := rl.GetShaderLocation(shader, "ambientColor")

    update_shader_values(
        &light_direction, &light_color, &ambient_color,
        int(light_direction_loc), int(light_color_loc), int(ambient_color_loc), 
        shader)

    imgui.CreateContext(nil)
	defer imgui.DestroyContext(nil)

    // Initialize ImGui Backend
    rlimgui.init()
    defer rlimgui.shutdown()

    // Main game loop
    for !rl.WindowShouldClose() {
        // update 
        dt := rl.GetFrameTime()
        update_camera(&camera, dt)

        // call imgui
        imgui_display(&light_direction, &light_color, &ambient_color)
        update_shader_values(
            &light_direction, &light_color, &ambient_color,
            int(light_direction_loc), int(light_color_loc), int(ambient_color_loc), 
            shader)

        // render
        rl.BeginDrawing()
        rl.ClearBackground({ 20, 20, 20, 255 })
        rl.BeginMode3D(camera)
        // Draw a grid and some simple geometry to see the rotation effect
        rl.DrawGrid(20, 2.0)
        draw_models(data.positions, data.sizes, model)
        rl.EndMode3D()

        imgui.Render()
		rlimgui.render_draw_data(imgui.GetDrawData())

        rl.EndDrawing()
    }
}

// package main

// import "core:fmt"

// main :: proc() {
//     names := []string{"Alice", "Bob", "Charlie"}
//     ages  := []int{25, 30, 35}

//     for _, i in names {
//         // Access both safe by reference or directly
//         fmt.printfln("%s is %d years old", names[i], ages[i])
//     }

//     // soa_zip lets you loop through them in parallel
//     for item in soa_zip(Name=names, Age=ages) {
//         fmt.printfln("%s is %d years old", item.Name, item.Age)
//     }
// }