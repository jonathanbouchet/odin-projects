#+feature dynamic-literals
package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:encoding/json"
import rl "vendor:raylib"

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
    /*
    - read a map tmj file and extracts its data for eahc of the 5 layers
    - initialized to nil, stays nil if the map does not have that layer
    - assembled all layer:data into a hash_table
    */

    floor_layer: ^Texture_Layer = nil
    wall_layer: ^Texture_Layer = nil
    props_layer: ^Texture_Layer = nil
    coins_layer: ^Texture_Layer = nil
    doors_layer: ^Texture_Layer = nil

    floor_layer = extract_layer_data(map_data, 1)
    if floor_layer != nil{
    defer delete(floor_layer.name)
    }

    wall_layer = extract_layer_data(map_data, 2)
    if wall_layer != nil{
    defer delete(wall_layer.name)
    }

    props_layer = extract_layer_data(map_data, 3)
    if props_layer != nil{
        defer delete(props_layer.name)
    }

    coins_layer = extract_layer_data(map_data, 5)
    if coins_layer != nil{
        defer delete(coins_layer.name)
    }

    doors_layer = extract_layer_data(map_data, 4)
    if doors_layer != nil{
        defer delete(doors_layer.name)
    }

    m := map[string]^Texture_Layer{
        "FLOOR" = floor_layer,
        "WALL" = wall_layer,
        "DOORS" = doors_layer,
        "PROPS" = props_layer,
        "COINS" = coins_layer,
    }

    return m
}

load_and_make_model :: proc(path: string, dim: rl.Vector3) -> rl.Model {
    /*
    - load a static texture and aaply it to a Model
    */
    path_cstring := strings.clone_to_cstring(path)
    defer delete(path_cstring)
    texture := rl.LoadTexture(path_cstring) // 32x32 pixels minimalist
    model := rl.LoadModelFromMesh(rl.GenMeshCube(dim.x, dim.y, dim.z)) // full cube
    model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = texture
    return model
}
