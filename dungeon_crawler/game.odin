package main

import "core:fmt"
import rl "vendor:raylib"

Game :: struct {
    camera: rl.Camera3D,
    player: Player,
    map_data1: Map_Data,
    level1: map[string]^Texture_Layer,
    wall: rl.Model,
    floor: rl.Model,
    door: rl.Model,
    walls_bb: [dynamic]rl.BoundingBox,
    doors_bb: [dynamic]rl.BoundingBox,
    debug: bool,
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

    game.wall = load_and_make_model("assets/textures/wall_minimalist_32x32_v3.png", rl.Vector3{1.0, 1.0, 1.0})
    game.floor = load_and_make_model("assets/textures/floor_minimalist_32x32.png", rl.Vector3{1.0, 0.01, 1.0})
    game.door = load_and_make_model("assets/textures/door_minimalist_32x32.png", rl.Vector3{1.0, 1.0, 0.0001})

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

    game.debug = true
}

draw_game :: proc(game: Game){
    draw_floor_layer_from_map(game.level1["FLOOR"]^, game.floor)
    draw_full_wall_from_layer(game.level1["WALL"]^, game.wall)
    draw_doors_from_layer(game.level1["DOORS"]^, game.door)
    if game.debug{
        for bb in game.walls_bb{
            center := (bb.max + bb.min) / 2
            rl.DrawCubeWiresV(center, rl.Vector3{1.0, 1.0, 1.0}, GREEN)
        }

        for do_bb in game.doors_bb{
            center := (do_bb.max + do_bb.min) / 2
            rl.DrawCubeWiresV(center, rl.Vector3{0.1, 1.0, 1.0}, GREEN)
        }

        draw_debug(game.player)
    }
}