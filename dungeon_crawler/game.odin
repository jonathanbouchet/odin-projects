package main

import "core:fmt"
import rl "vendor:raylib"

Game :: struct {
    player: Player,
    map_data1: Map_Data,
    level1: map[string]^Texture_Layer,
    wall_texture: rl.Texture,
    wall: rl.Model,
    floor_texture: rl.Texture,
    floor: rl.Model,
    door_texture: rl.Texture,
    door: rl.Model,
    walls_bb: [dynamic]rl.BoundingBox,
    doors_bb: [dynamic]rl.BoundingBox,
}

game_init :: proc() -> Game{
    game: Game
    return game
}

game_load :: proc(game: ^Game){
    // 1) for each level:
    // - read map data
    // - extract layers 
    // 2) load tiles and animations
    // 3) make boundingboxes

    // read input data for 1 map
    game.map_data1 = read_input_data("assets/maps/test4_v2_10x10.tmj", Map_Data)
    fmt.println(typeid_of(type_of(game.map_data1))) 
    fmt.printfln("# of layers in map 1: %v", len(game.map_data1.layers))
    game.level1 = extract_all_layers(game.map_data1)

    game.wall_texture = rl.LoadTexture("assets/textures/wall_minimalist_32x32_v3.png") // 32x32 pixels minimalist
    game.wall = rl.LoadModelFromMesh(rl.GenMeshCube(1.0, 1.0, 1.0)) // full cube
    game.wall.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = game.wall_texture

    game.floor_texture = rl.LoadTexture("assets/textures/floor_minimalist_32x32.png") // 32x32 pixels
    game.floor = rl.LoadModelFromMesh(rl.GenMeshCube(1.0, 0.01, 1.0)) // y-coordinate flat
    game.floor.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = game.floor_texture

    game.door_texture = rl.LoadTexture("assets/textures/door_minimalist_32x32.png") // 32x32 pixels
    game.door = rl.LoadModelFromMesh(rl.GenMeshCube(1.0, 1.0, 0.0001)) // z-coordinate flat
    game.door.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = game.door_texture

    game.walls_bb = make_boundary_boxes(
        texture_layer = game.level1["WALL"]^, 
        width = 1.0, 
        height = 1.0, 
        depth = 1.0,
    )

    game.doors_bb = make_boundary_boxes(
        texture_layer = game.level1["DOORS"]^,
        width = 0.1,
        height = 1.0,
        depth = 1.0,
    )
}

draw_game :: proc(game: Game){
}