package main

import "core:mem"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

WIDTH :: 640
HEIGHT :: 380
FPS :: 60
BACKGROUND :: rl.Color{0, 0, 28, 255}
BACKGROUND_BLACK :: rl.Color{20, 20, 20, 255 } // light black
GREEN :: rl.Color{57, 255, 20, 255}
TILE_X :: 10
TILE_Z :: 10
TILE_Y :: 2

Layer_Data :: struct {
    // struct should match the keys in the JSON file
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

Flame_Animation :: struct {
    frames: [4]rl.Model,
    position: rl.Vector3,
    animation_frame_length: f32,  // duration of a single animation frame
    animation_current_frame: i32, // index of the frame/png in the current animation
    run_frame_timer: f32,         // how long the current frame has been displayed, in seconds
}

read_data :: proc(filepath: string, $T: typeid) -> T {
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

draw_wall_layer_from_map :: proc(texture_layer: Texture_Layer, model: rl.Model, dir: Direction){
     /*
    - draw a "floor" for a given TILE_X and TILE_Z numbers
    - hardcoded for now, knowing the map is 10x10 tiles in X-Z plane
    - 1 'tile' is 1 3D unit: texture is mapped to a Cube Mesh wih dimension: rl.GenMeshCube(1.0, 1.0, 0.01)
    - y-position is fixed to 0 since this is the floor
    */
    if dir == .BACK{
        i, j, k: i32
        x, y, z: f32
        data := texture_layer.data
        for jj in 0..<TILE_Y{
            for id in 0..<len(data){
                if data[id] > 0 {
                    j = i32(id/10)
                    i = i32(id) - j*10
                    x = -4.5 + f32(i*1.0)
                    y = 0.5 + f32(jj*1.0)
                    z = -5.0
                    rl.DrawModelEx(model, rl.Vector3{x, y, z}, rl.Vector3{0, 1, 0}, 0.0, 1.0, rl.RAYWHITE)
                }
            }
        }
    } else if dir == .LEFT {
        i, j, k: i32
        x, y, z: f32
        data := texture_layer.data
        for jj in 0..<TILE_Y{
            for id in 0..<len(data){
                if data[id] > 0 {
                    j = i32(id/10)
                    i = i32(id) - j*10
                    x = -5.0
                    y = 0.5 + f32(jj*1.0)
                    z = -4.5 + f32(j*1.0)
                    rl.DrawModelEx(model, rl.Vector3{x, y, z}, rl.Vector3{0, 1, 0}, 90.0, 1.0, rl.RAYWHITE)
                }
            }
        }
    } else if dir == .RIGHT {
        i, j, k: i32
        x, y, z: f32
        data := texture_layer.data
        for jj in 0..<TILE_Y{
            for id in 0..<len(data){
                if data[id] > 0 {
                    j = i32(id/10)
                    i = i32(id) - j*10
                    x = 5.0
                    y = 0.5 + f32(jj*1.0)
                    z = -4.5 + f32(j*1.0)
                    rl.DrawModelEx(model, rl.Vector3{x, y, z}, rl.Vector3{0, 1, 0}, 90.0, 1.0, rl.RAYWHITE)
                }
            }
        }
    }
}

draw_floor_layer_from_map :: proc(texture_layer: Texture_Layer, model: rl.Model){
     /*
    - similar to draw_floor but for walls.
    - each direction keeps a X (LEFT or RIGHT) or Z constant (back)
    */
    i, j, k: i32
    x, y, z: f32
    data := texture_layer.data
    for id in 0..<len(data){
        if data[id] > 0 {
            j = i32(id/10)
            i = i32(id) - j*10
            x = -4.5 + f32(i*1.0)
            y = 0
            z = -4.5 + f32(j*1.0)
            rl.DrawModelEx(model, rl.Vector3{x, y, z}, rl.Vector3{1, 0, 0}, 0.0, 1.0, rl.RAYWHITE)
        }
    }
}

load_flames :: proc() -> [4]rl.Model {
    fl: [4]rl.Model
    for i in 0..<4 {
        path := fmt.tprintf("%s%d.png", "assets/textures/flame/frame_00", i)
        fmt.printfln("i%v, path:%v", i, path)
        path_cstring := strings.clone_to_cstring(path)
        defer delete(path_cstring)
        t := rl.LoadTexture(path_cstring)
        fmt.printfln("width: %v, height:%v", t.width, t.height)
        // defer rl.UnloadTexture(t)
        m := rl.LoadModelFromMesh(rl.GenMeshCube(1.0, 1.0, 0.0001))
        m.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = t
        fl[i] = m
    }
    return fl
}

draw_flames :: proc(fl: ^Flame_Animation) {
    frame_count := len(fl.frames)
    fl.run_frame_timer += rl.GetFrameTime()

    if frame_count == 0 {
        return
    }

    if frame_count > 1 && fl.animation_frame_length > 0 &&
       fl.run_frame_timer >= fl.animation_frame_length {
        fl.run_frame_timer -= fl.animation_frame_length
        fl.animation_current_frame =
            (fl.animation_current_frame + 1) % i32(frame_count)
    }

    rl.DrawModelEx(
        fl.frames[fl.animation_current_frame], 
        fl.position, 
        rl.Vector3{0, 0, 1}, 
        180.0, 
        1.0, 
        rl.RAYWHITE,
    )

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
    rl.InitWindow(WIDTH, HEIGHT, "dungeon")
    rl.SetTargetFPS(FPS)

    // read input data
    map_data := read_input_data("assets/maps/dungeon_crawler_minimalist_v2.tmj", Map_Data)
    defer delete(map_data.layers)
    fmt.println(typeid_of(type_of(map_data))) 
    fmt.printfln("# of layers: %v", len(map_data.layers))
    // fmt.printfln("raw data: %v", map_data)

    layers := extract_all_layers(map_data)
    // fmt.printfln("layers: %", layers)
    // fmt.printfln("floor: %v", layers["FLOOR"]^)

    defer delete(layers)

    wall_texture := rl.LoadTexture("assets/textures/wall_minimalist_32x32_v2.png") // 32x32 pixels minimalist
    defer rl.UnloadTexture(wall_texture)

    floor_texture := rl.LoadTexture("assets/textures/floor_minimalist_32x32.png") // 32x32 pixels
    defer rl.UnloadTexture(floor_texture)

    wall := rl.LoadModelFromMesh(rl.GenMeshCube(1.0, 1.0, 0.01)) // z-coordinate flat
    wall.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = wall_texture

    floor := rl.LoadModelFromMesh(rl.GenMeshCube(1.0, 0.01, 1.0)) // y-coordinate flat
    floor.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = floor_texture

    flames := load_flames()

    flame := Flame_Animation{
        frames = flames,
        position = {0, 0.5, 0},
        animation_frame_length = 0.1,
        animation_current_frame = 0,
        run_frame_timer = 0.0,
    }

    player := Player{
        position = rl.Vector3{0, 0, 0},
        speed = 5,
        eyes = 1,
        yaw = 0.0,
        pitch = 0.0,
        sensitivity = 0.003,
    }

    camera := rl.Camera3D{
        up         = { 0.0, 1.0, 0.0 },  // Camera up vector (rotation towards target)
        target     = { 0.0, 1.0, 10.0},
        fovy       = 60.0,               // Camera field-of-view Y
        projection = .PERSPECTIVE,       // Camera projection type
    }

    rl.DisableCursor() 

    for !rl.WindowShouldClose() {
        // update
        update_player(&player, &camera)

        // render
        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND_BLACK)
        rl.BeginMode3D(camera)

        draw_wall_layer_from_map(layers["LEFT"]^, wall, .LEFT)
        draw_wall_layer_from_map(layers["RIGHT"]^, wall, .RIGHT)
        draw_wall_layer_from_map(layers["BACK"]^, wall, .BACK)
        draw_floor_layer_from_map(layers["FLOOR"]^, floor)

        draw_flames(&flame)

        rl.EndMode3D()
        draw_debug()
        rl.EndDrawing()
    }
    rl.CloseWindow()
}