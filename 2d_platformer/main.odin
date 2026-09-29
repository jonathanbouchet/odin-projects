package main

import "core:os"
import "core:fmt"
import "core:mem"
import "core:slice"
import "core:math"
import "core:encoding/json"
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

Texture_Layer :: struct {
    id: i32,
    data: [NUM_TILE_X * NUM_TILE_Y]i32,
    height: i32,
    width: i32,
    name: string
}

Map_Data :: struct {
    layers: [dynamic]Texture_Layer,
    tileheight: i32,
    tilewidth: i32,
    width: i32,
    height: i32
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

draw_background :: proc (texture: rl.Texture) {
    x := i32(0)
    y := i32(5)
    source_rect := rl.Rectangle{f32(x * TILE_WIDTH), f32(y * TILE_WIDTH), TILE_WIDTH, TILE_WIDTH }
    for i in 0..<NUM_TILE_X {
        for j in 0..<NUM_TILE_Y {
            // center of the screen
            dest_rect := rl.Rectangle{
                f32(i*TILE_WIDTH), 
                f32(j*TILE_WIDTH), 
                TILE_WIDTH, 
                TILE_WIDTH
            } 
            rl.DrawTexturePro(
                texture, 
                source_rect, 
                dest_rect, 
                rl.Vector2{0, 0}, 
                0.0, 
                rl.RAYWHITE
            )
        }
    }
}

draw_layer :: proc (texture: rl.Texture, layer: ^Texture_Layer) {
    x: f32
    y: f32
    i: f32
    j: f32
    tile_value: i32
    for tile_id in 0..<len(layer.data) {
        if layer.data[tile_id] > 0 {
            tile_value = layer.data[tile_id]
            y = math.floor_f32(f32(tile_value) / NUM_TILE_X)
            x = f32(tile_value - 1) - f32(y*NUM_TILE_X)
            source_rect := rl.Rectangle{f32(x * TILE_WIDTH), f32(y * TILE_WIDTH), TILE_WIDTH, TILE_WIDTH }

            j = math.floor_f32(f32(tile_id) / NUM_TILE_X)
            i = f32(tile_id % NUM_TILE_X)

            // fmt.printfln("tile_id: %v, tile_value: %v, x: %v, y: %v, i: %v, j: %v", tile_id, tile_value, x,y,i,j)

            dest_rect := rl.Rectangle{
                    f32(i*TILE_WIDTH), 
                    f32(j*TILE_WIDTH), 
                    TILE_WIDTH, 
                    TILE_WIDTH
                } 
            rl.DrawTexturePro(
                texture, 
                source_rect, 
                dest_rect, 
                rl.Vector2{0, 0}, 
                0.0, 
                rl.RAYWHITE
            )
        }
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

    for &layer in map_data.layers {
        if layer.id == 3 {
            background_layer = &layer
            break
        }
    }

    if background_layer != nil {
        fmt.println("Found layer:", background_layer.name)
    }

    for &layer in map_data.layers {
        if layer.id == 2 {
            platform_layer = &layer
            break
        }
    }
    if platform_layer != nil {
        fmt.println("Found layer:", platform_layer.name)
    }

    for &layer in map_data.layers {
        if layer.id == 1 {
            props_layer = &layer
            break
        }
    }
    if props_layer != nil {
        fmt.println("Found layer:", props_layer.name)
    }

    fmt.printfln("platform layer: %v", platform_layer)
    fmt.println(typeid_of(type_of(platform_layer))) 

    texture := rl.LoadTexture("assets/tilemap.png")
    defer rl.UnloadTexture(texture)

    for !rl.WindowShouldClose(){
        // logic

        // update

        //render
        rl.BeginDrawing()
        rl.ClearBackground(COLOR)

        // draw_background(texture)
        draw_layer(texture, background_layer)
        draw_layer(texture, platform_layer)
        draw_layer(texture, props_layer)

        draw_debug()
        rl.EndDrawing()
    }


}