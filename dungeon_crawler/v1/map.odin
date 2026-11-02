package main

import rl "vendor:raylib"

// Layer_Data :: struct {
//     // struct should match the keys in the JSON file
//     data: [100]i32,
//     direction: string,
// }

// Level_Data :: struct {
//     level: [dynamic]Layer_Data,
// }

Direction :: enum{
    LEFT,
    RIGHT,
    BACK,
    FRONT,
}

draw_wall_layer_from_map :: proc(texture_layer: Texture_Layer, model: rl.Model, dir: Direction){
     /*
    - draw a "floor" for a given TILE_X and TILE_Z numbers
    - hardcoded for now, knowing the map is 10x10 tiles in X-Z plane
    - 1 'tile' is 1 3D unit: texture is mapped to a Cube Mesh wih dimension: rl.GenMeshCube(1.0, 1.0, 0.01)
    - y-position is fixed to 0 since this is the floor
    */
    if dir == .BACK{
        i, j: i32
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
        i, j: i32
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
        i, j: i32
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
    i, j: i32
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