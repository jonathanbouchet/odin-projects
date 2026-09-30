package main

import "core:fmt"
import "core:mem"
import "core:slice"
import "core:math"
import rl "vendor:raylib"

WIDTH :: 640
HEIGHT :: 320
TILE_WIDTH :: 32
NUM_TILE_X :: WIDTH / 32
NUM_TILE_Y :: HEIGHT / 32
TARGET_FPS :: 60
// COLOR :: rl.Color{252, 223, 205, 255}
COLOR :: rl.Color{25, 25, 25, 255}

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

draw_debug :: proc() {
    rl.DrawFPS(0, 0)
    rl.DrawLineV(rl.Vector2{0, HEIGHT/2}, {WIDTH, HEIGHT/2}, rl.Color{57, 255, 20, 255})
    rl.DrawLineV(rl.Vector2{WIDTH/2, 0}, {WIDTH/2, HEIGHT}, rl.Color{57, 255, 20, 255})
}

main :: proc(){
    show_memory()
    // raylib initialization
    // rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})
    rl.InitWindow(WIDTH, HEIGHT, "2d platform")
    rl.SetTargetFPS(TARGET_FPS)
    defer rl.CloseWindow()

    // read input data
    map_data := read_input_data("assets/2d_map_v4.tmj", Map_Data)
    // delete the dynamically alocated fields
    defer delete(map_data.layers)
    fmt.println(typeid_of(type_of(map_data))) 
    fmt.printfln("# of layers: %v", len(map_data.layers))
    // fmt.printfln("map data: %v", map_data.layers[:])

    // test filtering
    // props_layer:= slice.filter(map_data.layers[:], proc(layer: Texture_Layer) -> bool {
    //     return layer.id == 2 
    // })
    // fmt.printfln("props layer: %v", props_layer)
    // fmt.println(typeid_of(type_of(props_layer))) 
    // defer delete(props_layer)

    // another to filter the slice
    // advantage: avoids allocating a new array
    background_layer: ^Texture_Layer = nil
    platform_layer: ^Texture_Layer = nil
    props_layer: ^Texture_Layer = nil
    collision_layer: ^Texture_Layer = nil

    background_layer = extract_layer_data(map_data, 3)
    platform_layer = extract_layer_data(map_data, 2)
    props_layer = extract_layer_data(map_data, 1)
    collision_layer = extract_layer_data(map_data, 6)

    if background_layer != nil {
        fmt.println("Found layer:", background_layer.name)
    }

    if platform_layer != nil {
        fmt.println("Found layer:", platform_layer.name)
    }

    if props_layer != nil {
        fmt.println("Found layer:", props_layer.name)
    }

    if collision_layer != nil {
        fmt.println("Found layer:", collision_layer.name)
    }

    fmt.printfln("platform layer: %v", platform_layer)
    fmt.println(typeid_of(type_of(platform_layer))) 

    texture := rl.LoadTexture("assets/tilemap.png")
    defer rl.UnloadTexture(texture)

    // player
    player := Player{
        position = rl.Vector2{f32(150), f32(100)},
        velocity = rl.Vector2{0, 0},
        rotation = 0.0,
        width = f32(32),
        height = f32(32),
        color = rl.Color{ 0, 0, 28, 255 },
        grounded = false
    }

    for !rl.WindowShouldClose(){
        // logic

        // update
        update_player(&player, collision_layer)

        //render
        rl.BeginDrawing()
        rl.ClearBackground(COLOR)

        // draw_background(texture)
        draw_layer(texture, background_layer, false)
        draw_layer(texture, platform_layer, false)
        draw_layer(texture, props_layer, false)
        draw_layer(texture, collision_layer, true)
        draw_player(player)

        draw_debug()
        rl.EndDrawing()
    }


}