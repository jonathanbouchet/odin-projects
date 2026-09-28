package main

import "core:os"
import "core:fmt"
import "core:mem"
import "core:encoding/json"
import rl "vendor:raylib"

WIDTH :: 640
HEIGHT :: 320
TILE_WIDTH :: 32
NUM_TILE_X :: WIDTH / 32
NUM_TILE_Y :: HEIGHT / 32
TARGET_FPS :: 60
COLOR :: rl.Color{252, 223, 205, 255}

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

Layer :: struct {
    id: i32,
    data: [NUM_TILE_X * NUM_TILE_Y]i32,
    height: i32,
    width: i32,
    name: string
}

Layer_Data :: struct {
    layers: [dynamic]Layer,
    tileheight: i32,
    tilewidth: i32,
    width: i32,
    height: i32
}

read_input_data :: proc(filepath: string, $T: typeid) -> T {
    input_data, ok := os.read_entire_file(filepath, context.temp_allocator)
    if ok != nil {
        fmt.eprintln("Failed to read file.")
        return T{}
	}
    defer free_all(context.temp_allocator)

	data: T
	err := json.unmarshal(input_data, &data)
	if err != nil {
		fmt.eprintln("Parsing error:", err)
        return T{}
	}
    return data
}

main :: proc(){
    show_memory()
    // raylib initialization
    rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})
    rl.InitWindow(WIDTH, HEIGHT, "2d platform")
    rl.SetTargetFPS(TARGET_FPS)
    defer rl.CloseWindow()

    // read input data
    map_data := read_input_data("assets/2d_map.tmj", Layer_Data)
    defer delete(map_data.layers)
    // defer {
    //     for layer in map_data.layers {
    //         delete(layer.data)
    //     }
    //     delete(map_data.layers)
    // }
   fmt.println(typeid_of(type_of(map_data))) 
   fmt.printfln("# of layers: %v", len(map_data.layers))

    for !rl.WindowShouldClose(){
        // logic

        // update

        //render
        rl.BeginDrawing()
        rl.ClearBackground(COLOR)
        rl.EndDrawing()
    }


}