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

extract_layer_data :: proc (data: Map_Data, layer_id: i32) -> (layer: ^Texture_Layer, found: bool) {
    /*
    - extract a particular Texture_Layer given a layer_id
    */
    for &layer in data.layers {
        if layer.id == layer_id {
            return &layer, true
        }
    }
    return nil, false
}

extract_all_layers :: proc (map_data: Map_Data) -> map[string]^Texture_Layer {
    m := make(map[string]^Texture_Layer)

    if floor_layer, ok := extract_layer_data(map_data, 1); ok{
        m["FLOOR"] = floor_layer
        defer delete(floor_layer.name)
    } else {
        m["FLOOR"] = nil
    }
    if wall_layer, ok := extract_layer_data(map_data, 2); ok{
        m["WALL"] = wall_layer
        defer delete(wall_layer.name)
    }else {
        m["WALL"] = nil
    }
    if doors_layer, ok := extract_layer_data(map_data, 4); ok{
        m["DOORS"] = doors_layer
        defer delete(doors_layer.name)
    }else {
        m["DOORS"] = nil
    }
    if props_layer, ok := extract_layer_data(map_data, 3); ok{
        m["PROPS"] = props_layer
        defer delete(props_layer.name)
    }else {
        m["PROPS"] = nil
    }
    if coins_layer, ok := extract_layer_data(map_data, 5); ok{
        m["COINS"] = coins_layer
        defer delete(coins_layer.name)
    }else {
        m["COINS"] = nil
    }
    return m
}