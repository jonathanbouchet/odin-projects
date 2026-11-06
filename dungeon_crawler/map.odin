package main

import "core:fmt"
import rl "vendor:raylib"

make_boundary_boxes :: proc(texture_layer: Texture_Layer, width: f32, height: f32, depth: f32) -> [dynamic]rl.BoundingBox {
    /*
    - make an dynamic array of BoundingBoxes of all tiles in that layer
    - take width(x), height(y), depth(z) as parameters to fit with different tiles:
        - wall: 1,   1, 1
        - coin: 1,   1, 1
        - door: 0.1, 1, 1
    */
    fmt.printfln("in make_boundary_boxes: %v", texture_layer)
    bb: [dynamic]rl.BoundingBox
    i, j: i32
    x, y, z: f32
    data := texture_layer.data
    min_x: f32 = -TILE_X/2 + 0.5
    for id in 0..<len(data){
        if data[id] > 0 {
            j = i32(id/10)
            i = i32(id) - j*10
            x = min_x + f32(i*1.0) - 0.5
            y = 0.0
            z = min_x + f32(j*1.0) - 0.5

            xx := x + width
            yy:f32 = height
            zz := z + depth

            append(&bb, rl.BoundingBox{rl.Vector3{x, y, z}, rl.Vector3{xx, yy, zz}})
        }
    }
    return bb
}

draw_floor_layer_from_map :: proc(texture_layer: Texture_Layer, model: rl.Model){
     /*
    - extract from the data array the id of the tile
    - decode the x,y,z position from the indexes
    - indexes: i, j, k are extract by assuming a 10x10 map
    */
    i, j: i32
    x, y, z: f32
    min: f32 = -TILE_X/2 + 0.5
    data := texture_layer.data
    for id in 0..<len(data){
        if data[id] > 0 {
            j = i32(id/TILE_X)
            i = i32(id) - j*TILE_X
            x = min + f32(i*1.0)
            y = 0
            z = min + f32(j*1.0)
            rl.DrawModelEx(model, rl.Vector3{x, y, z}, rl.Vector3{1, 0, 0}, 0.0, 1.0, rl.RAYWHITE)
        }
    }
}

draw_full_wall_from_layer :: proc(texture_layer: Texture_Layer, model: rl.Model){
    /*
    - extract from the data array the id of the tile
    - decode the x,y,z position from the indexes
    - indexes: i, j, k are extract by assuming a 10x10 map
    - to make a wall of height = 2, use the loop over TILE_Y
    */
    // fmt.printfln("in draw_full_wall_from_layer: %v", texture_layer)
    i, j: i32
    x, y, z: f32
    data := texture_layer.data
    min_x: f32 = -TILE_X/2 + 0.5
    // for jj in 0..<TILE_Y{
    for jj in 0..<1{
        for id in 0..<len(data){
            if data[id] > 0 {
                j = i32(id/10)
                i = i32(id) - j*10
                x = min_x + f32(i*1.0)
                y = 0.5 + f32(jj*1.0)
                z = min_x + f32(j*1.0)
                rl.DrawModelEx(model, rl.Vector3{x, y, z}, rl.Vector3{0, 1, 0}, 0.0, 1.0, rl.RAYWHITE)
            }
        }
    }
}

draw_doors_from_layer :: proc(texture_layer: Texture_Layer, model: rl.Model){
      /*
    - extract from the data array the id of the tile
    - decode the x,y,z position from the indexes
    - indexes: i, j, k are extract by assuming a 10x10 map
    - y-position is hard-coded to half a unit
    */
    i, j: i32
    x, y, z: f32
    data := texture_layer.data
    min_x: f32 = -TILE_X/2 + 0.5
    epsilon: f32 = 0.5
    for id in 0..<len(data){
        if data[id] > 0 {
            j = i32(id/10)
            i = i32(id) - j*10
            x = min_x + f32(i*1.0) - epsilon
            y = 0.5
            z = min_x + f32(j*1.0)
            rl.DrawModelEx(model, rl.Vector3{x, y, z}, rl.Vector3{0, 1, 0}, 90.0, 1.0, rl.RAYWHITE)
        }
    }
}
