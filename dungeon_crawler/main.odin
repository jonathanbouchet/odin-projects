package main

import "core:os"
import "core:mem"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"
import "core:encoding/json"

WIDTH :: 640
HEIGHT :: 640
FPS :: 60
BACKGROUND :: rl.Color{0, 0, 28, 255}
GREEN :: rl.Color{57, 255, 20, 255}
TILE_X :: 10
TILE_Z :: 10
TILE_Y :: 2

Layer_Data :: struct {
    data: [100]i32,
    direction: string,
}

Level_Data :: struct {
    level: [dynamic]Layer_Data,
}

Direction :: enum{
    LEFT,
    RIGHT,
    BACK,
    FRONT,
}

read_input_data :: proc(filepath: string, $T: typeid) -> T {
    // as a temporary allocation, use the temp_allocator
    input_data, ok := os.read_entire_file(filepath, context.temp_allocator)
    if ok != nil {
        fmt.eprintln("Failed to read file.")
        return T{}
	}
    // deleting the memory allocated to read the file
    defer free_all(context.temp_allocator)

	data: T
	err := json.unmarshal(input_data, &data)
	if err != nil {
		fmt.eprintln("Parsing error:", err)
        return T{}
	}
    return data
}

draw_floor:: proc(floor: rl.Model) {
    x: f32
    y: f32 = 0.0
    z: f32
    for i in 0..<TILE_X {
            for k in 0..<TILE_Z{
                x = -4.5 + f32(i*1.0)
                z = -4.5 + f32(k*1.0)
                rl.DrawModelEx(floor, rl.Vector3{x, y, z}, rl.Vector3{1, 0, 0}, 0.0, 1.0, rl.RAYWHITE)
            }
        }
}

draw_wall :: proc(wall: rl.Model, dir: Direction) {
    x: f32
    y: f32
    z: f32
    if dir == .BACK {
    for j in 0..<TILE_Y{
            for i in 0..<TILE_X {
                x = -4.5 + f32(i*1.0)
                y = 0.5 + f32(j*1.0)
                z = -5.0
                rl.DrawModelEx(wall, rl.Vector3{x, y, z}, rl.Vector3{1, 0, 0}, 0.0, 1.0, rl.RAYWHITE)
            }
        }
    } else if dir == .LEFT{
        for j in 0..<TILE_Y{
            for k in 0..<TILE_Z {
                x = -5.0
                y = 0.5 + f32(j*1.0)
                z = -4.5 + f32(k*1.0)
                rl.DrawModelEx(wall, rl.Vector3{x, y, z}, rl.Vector3{0, 1, 0}, 90.0, 1.0, rl.RAYWHITE)
            }
        }
    } else if dir == .RIGHT{
        for j in 0..<TILE_Y{
            for k in 0..<TILE_Z {
                x = 5.0
                y = 0.5 + f32(j*1.0)
                z = -4.5 + f32(k*1.0)
                rl.DrawModelEx(wall, rl.Vector3{x, y, z}, rl.Vector3{0, 1, 0}, 90.0, 1.0, rl.RAYWHITE)
            }
        }
    } 
}

draw_debug :: proc() {
    /*
    various "debug" utils:
    - draw the FPS number
    - draw lines, h and v, representing the mid-screen
    */
    rl.DrawFPS(0, 0)
    rl.DrawLineV(rl.Vector2{0, HEIGHT/2}, {WIDTH, HEIGHT/2}, GREEN)
    rl.DrawLineV(rl.Vector2{WIDTH/2, 0}, {WIDTH/2, HEIGHT}, GREEN)
}

main :: proc() {
    tracking: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking)

    // defer {
    //     fmt.printfln(
    //         "Current memory: %d bytes, peak memory: %d bytes",
    //         tracking.current_memory_allocated,
    //         tracking.peak_memory_allocated,
    //     )

    //     if len(tracking.allocation_map) > 0 {
    //         fmt.eprintln("Unfreed allocations:")

    //         for _, entry in tracking.allocation_map {
    //             fmt.eprintf(
    //                 "- %d bytes @ %v\n",
    //                 entry.size,
    //                 entry.location,
    //             )
    //         }
    //     }

    //     mem.tracking_allocator_destroy(&tracking)
    // }

    // // Track allocations made through context.allocator.
    // tracking: mem.Tracking_Allocator
    // mem.tracking_allocator_init(&tracking, context.allocator)

    // // Any allocation using context.allocator is now tracked.
    // context.allocator = mem.tracking_allocator(&tracking)

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
    rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})
    rl.InitWindow(WIDTH, HEIGHT, "character animation")
    rl.SetTargetFPS(FPS)

    level_data := read_input_data("level.json", Level_Data)
    fmt.printfln("level data: %v", level_data.level)
    // for i in 0..<len(level_data.level){
    //     defer delete(level_data.level[i].direction)
    // }
    defer delete(level_data.level[0].direction)
    defer delete(level_data.level[1].direction)
    defer delete(level_data.level[2].direction)
    defer delete(level_data.level)

    wall_texture := rl.LoadTexture("assets/ROUNDBRICKS.png") // 32x32 pixels
    // wall_texture := rl.LoadTexture("assets/wall_test.png") // 32x32 pixels
    // wall_texture := rl.LoadTexture("assets/wall_test_64x64.png") // 64x64 pixels
    //wall_texture := rl.LoadTexture("assets/wall_test_GB_colors_32x32.png") // 32x32 pixels GB colors
    defer rl.UnloadTexture(wall_texture)

    floor_texture := rl.LoadTexture("assets/FLATSTONES.png") // 32x32 pixels
    defer rl.UnloadTexture(floor_texture)

    wall := rl.LoadModelFromMesh(rl.GenMeshCube(1.0, 1.0, 0.01)) // z-coordinate flat
    wall.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = wall_texture

    floor := rl.LoadModelFromMesh(rl.GenMeshCube(1.0, 0.01, 1.0)) // y-coordinate flat
    floor.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = floor_texture

    // camera
    camera := rl.Camera3D{
        position   = { 0.2, 1.0, 0.2 },  // Camera position
        target     = { 0.185, 1.0, -10.0 },// Camera looking at point
        up         = { 0.0, 1.0, 0.0 },  // Camera up vector (rotation towards target)
        fovy       = 60.0,               // Camera field-of-view Y
        projection = .PERSPECTIVE,       // Camera projection type
    }

    rl.DisableCursor() 

    for !rl.WindowShouldClose() {
        // update
        dt := rl.GetFrameTime()
        rl.UpdateCamera(&camera, .FIRST_PERSON)

        // render
        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND)
        rl.BeginMode3D(camera)

        // draw floor
        draw_floor(floor)

        // draw back wall
        // draw_wall(wall, .BACK)
        // test: select a given layer
        for layer in level_data.level {
            // fmt.printfln("layer: %v", layer)
            // fmt.printf("direction: %v, type: %v\n", layer.direction, typeid_of(type_of(layer.direction)))
            test_string: string = "back"
            if strings.compare(layer.direction, test_string) == 0 {
                // fmt.printfln("selected direction: %v", layer.direction)
                back_data := layer.data
                i, j, k: i32
                x, y, z: f32
                for jj in 0..<TILE_Y{
                    for id in 0..<len(back_data){
                        if back_data[id] > 0 {
                            j = i32(id/10)
                            i = i32(id) - j*10
                            x = -4.5 + f32(i*1.0)
                            y = 0.5 + f32(jj*1.0)
                            z = -5.0
                            rl.DrawModelEx(wall, rl.Vector3{x, y, z}, rl.Vector3{1, 0, 0}, 0.0, 1.0, rl.RAYWHITE)
                        }
                    }
                }
            }
        }

        // draw left wall
        draw_wall(wall, .LEFT)

        // draw right wall
        draw_wall(wall,. RIGHT)

        rl.EndMode3D()
        draw_debug()
        rl.EndDrawing()
    }
    rl.CloseWindow()
    // for i in 0..<len(level_data.level){
    //     defer delete(level_data.level[i].direction)
    // }
}