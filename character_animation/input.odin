package main

import "core:os"
import "core:fmt"
import "core:encoding/json"

Collision_Layer :: struct {
    height: f32,
    id: i32,
    rotation: f32,
    width: f32,
    x: f32,
    y: f32
}

Texture_Layer :: struct {
    id: i32,
    data: [NUM_TILE_X * NUM_TILE_Y]i32,
    height: i32,
    width: i32,
    name: string,
    objects: []Collision_Layer
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

extract_layer_data :: proc (data: Map_Data, layer_id: i32) -> ^Texture_Layer {
    current_layer: ^Texture_Layer = nil
    for &layer in data.layers {
        if layer.id == layer_id {
            current_layer = &layer
            break
        }
    }
    return current_layer
}