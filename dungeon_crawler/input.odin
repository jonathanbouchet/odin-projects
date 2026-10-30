#+feature dynamic-literals
package main

import "core:os"
import "core:fmt"
import "core:encoding/json"

Texture_Layer :: struct {
    id: i32,
    data: [TILE_X * TILE_Z]i32,
    height: i32,
    width: i32,
    name: string,
}

Map_Data :: struct {
    layers: [dynamic]Texture_Layer,
    tileheight: i32,
    tilewidth: i32,
    width: i32,
    height: i32,
}

read_input_data :: proc(filepath: string, $T: typeid) -> T {
    /* 
    - read Tiled exported map to JSON (.tmj extension)
    - parse Tiled Layers and extract data: width, height, tileID array
    */

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

extract_layer_data :: proc (data: Map_Data, layer_id: i32) -> ^Texture_Layer {
    /*
    - extract a particular Texture_Layer given a layer_id
    */
    current_layer: ^Texture_Layer = nil
    for &layer in data.layers {
        if layer.id == layer_id {
            current_layer = &layer
            break
        }
    }
    return current_layer
}

extract_all_layers :: proc (map_data: Map_Data) -> map[string]^Texture_Layer {
    // m := make(map[int]^Texture_Layer)

    floor_layer: ^Texture_Layer = nil
    back_wall_layer: ^Texture_Layer = nil
    right_wall_layer: ^Texture_Layer = nil
    left_wall_layer: ^Texture_Layer = nil
    room_layer: ^Texture_Layer = nil

    floor_layer = extract_layer_data(map_data, 1)
    defer delete(floor_layer.name)

    back_wall_layer = extract_layer_data(map_data, 4)
    defer delete(back_wall_layer.name)

    left_wall_layer = extract_layer_data(map_data, 2)
    defer delete(left_wall_layer.name)

    right_wall_layer = extract_layer_data(map_data, 3)
    defer delete(right_wall_layer.name)

    room_layer = extract_layer_data(map_data, 5)
    defer delete(room_layer.name)

    m := map[string]^Texture_Layer{
        "FLOOR" = floor_layer,
        "BACK" = back_wall_layer,
        "LEFT" = left_wall_layer,
        "RIGHT" = right_wall_layer,
        "ROOM" = room_layer,
    }

    return m
}