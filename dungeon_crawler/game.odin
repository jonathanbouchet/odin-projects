package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

Game :: struct {
    camera: rl.Camera3D,
    player: Player,
    map_data1: Map_Data,
    level1: map[string]^Texture_Layer,
    map_data2: Map_Data,
    level2: map[string]^Texture_Layer,
    wall: rl.Model,
    floor: rl.Model,
    door: rl.Model,
    walls_bb: [dynamic]rl.BoundingBox,
    doors_bb: [dynamic]rl.BoundingBox,
    debug: bool,
    current_level_id: i32,
    current_level: ^map[string]^Texture_Layer,
    flames: [dynamic]rl.Model,
    num_flames: i32,
    flame_animations: [dynamic]Animation_To_Model,
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
    // 3) make bounding boxes

    // read input data for 1 map
    game.map_data1 = read_input_data("assets/maps/test4_v2_10x10.tmj", Map_Data)
    fmt.println(typeid_of(type_of(game.map_data1))) 
    fmt.printfln("# of layers in map 1: %v", len(game.map_data1.layers))
    game.level1 = extract_all_layers(game.map_data1)

    game.map_data2 = read_input_data("assets/maps/test3_10x10.tmj", Map_Data)
    fmt.println(typeid_of(type_of(game.map_data2))) 
    fmt.printfln("# of layers in map 2: %v", len(game.map_data2.layers))
    game.level2 = extract_all_layers(game.map_data2)

    game.current_level_id = 1
    game.current_level = &game.level1

    game.wall = load_and_make_model("assets/textures/wall_minimalist_32x32_v3.png", rl.Vector3{1.0, 1.0, 1.0})
    game.floor = load_and_make_model("assets/textures/floor_minimalist_32x32.png", rl.Vector3{1.0, 0.01, 1.0})
    game.door = load_and_make_model("assets/textures/door_minimalist_32x32.png", rl.Vector3{1.0, 1.0, 0.0001})

    game_make_animations(game=game, path="assets/textures/flame2/Sprite-000", start_anim=1, max_anim=7, layer="PROPS")
    game_make_bb(game)
    game.debug = true
}

game_draw :: proc(game: Game){
    draw_floor_layer_from_map(game.current_level["FLOOR"]^, game.floor)
    draw_full_wall_from_layer(game.current_level["WALL"]^, game.wall)
    draw_doors_from_layer(game.current_level["DOORS"]^, game.door)
    if game.debug{
        for bb in game.walls_bb{
            center := (bb.max + bb.min) / 2
            rl.DrawCubeWiresV(center, rl.Vector3{1.0, 1.0, 1.0}, GREEN if !game.player.is_colliding else rl.RED)
        }

        for do_bb in game.doors_bb{
            center := (do_bb.max + do_bb.min) / 2
            rl.DrawCubeWiresV(center, rl.Vector3{0.1, 1.0, 1.0}, GREEN if !game.player.is_colliding else rl.RED)
        }
    }
}


game_update :: proc(game: ^Game) {
    dt := rl.GetFrameTime()
    move_speed := game.player.speed * dt

    mouse_delta := rl.GetMouseDelta()
    game.player.yaw -= mouse_delta.x * game.player.sensitivity
    game.player.pitch -= mouse_delta.y * game.player.sensitivity

    max_pitch: f32 = math.PI / 2.0 - 0.01
    // game.player.pitch = clamp_f32(game.player.pitch, -max_pitch, max_pitch)
    game.player.pitch = 0

    forward := rl.Vector3{
        math.sin(game.player.yaw),
        0,
        math.cos(game.player.yaw),
    }
    right := rl.Vector3{
        math.cos(game.player.yaw),
        0,
        -math.sin(game.player.yaw),
    }

    // Combine input directions into one world-space movement vector.
    move := rl.Vector3{}
    if rl.IsKeyDown(.UP)    { move += forward }
    if rl.IsKeyDown(.DOWN)  { move -= forward }
    if rl.IsKeyDown(.LEFT)  { move += right }
    if rl.IsKeyDown(.RIGHT) { move -= right }

    // Prevent diagonal movement from being faster.
    if rl.Vector3Length(move) > 0 {
        move = rl.Vector3Normalize(move) * move_speed
    }

    game.player.is_colliding = false

    // Move and resolve X first.
    game.player.position.x += move.x
    player_bb := player_bounding_box_adjusted(game.player)
    for wall in game.walls_bb {
        if rl.CheckCollisionBoxes(wall, player_bb) {
            game.player.position.x -= move.x
            game.player.is_colliding = true
            break
        }
    }

    // doors are only along X axis so we check only X for a door collision
    for door in game.doors_bb {
        if rl.CheckCollisionBoxes(door, player_bb) {
            // game.player.position.x -= move.x
            game.player.is_colliding = true
            if rl.IsKeyPressed(.SPACE){
                game_switch_level(game)
            }
            break
        }
    }

    // Then move and resolve Z, using the possibly updated X position.
    game.player.position.z += move.z
    player_bb = player_bounding_box_adjusted(game.player)
    for wall in game.walls_bb {
        if rl.CheckCollisionBoxes(wall, player_bb) {
            game.player.position.z -= move.z
            game.player.is_colliding = true
            break
        }
    }

    game.camera.position = rl.Vector3{
        game.player.position.x,
        game.player.position.y + game.player.eyes,
        game.player.position.z,
    }

    direction := rl.Vector3{
        math.cos(game.player.pitch) * math.sin(game.player.yaw),
        math.sin(game.player.pitch),
        math.cos(game.player.pitch) * math.cos(game.player.yaw),
    }
    game.camera.target = game.camera.position + direction
}


game_switch_level :: proc(game: ^Game){
    if game.current_level_id == 1{
        game.current_level_id = 2
        game.current_level = &game.level2
        // TO DO: need the door location for spawning the player

        // update the bb of the current level
        // clear existing bb before updating them
        // wrong: need to delete entirely because clear does not free the underlying heap-allocated memory
        // -> the capacity (cap()) remains intact
        delete(game.walls_bb)
        delete(game.doors_bb)
        game_make_bb(game)
    } else {
        game.current_level_id = 1
        game.current_level = &game.level1

        // clear existing bb before updating them
        delete(game.walls_bb)
        delete(game.doors_bb)
        game_make_bb(game)
    }
}

game_make_bb :: proc(game: ^Game){
    game.walls_bb = make_boundary_boxes(
        texture_layer = game.current_level["WALL"]^, 
        width = 1.0, 
        height = 1.0, 
        depth = 1.0,
        collider_type="wall",
    )
    // increasing door's bb from 0.1 to 0.5 for allowing K pressed to switch level
    game.doors_bb = make_boundary_boxes(
        texture_layer = game.current_level["DOORS"]^,
        width = 0.5,
        height = 1.0,
        depth = 1.0,
        collider_type="door",
    )
}

game_make_animations :: proc(game: ^Game, path: string, start_anim: i32, max_anim: i32, layer: string){
    game.flames = make_model_from_animations(
        // path="assets/textures/flame/frame_00", 
        path=path, 
        start_anim=start_anim, 
        max_anim=max_anim,
        mesh_cube = [3]f32{1.0, 1.0, 0.0001},
    )
    game.num_flames = len(game.current_level[layer].data)
    game.flame_animations = make([dynamic]Animation_To_Model, 0, game.num_flames)

    i, j: i32
    x, y, z: f32
    data := game.current_level["PROPS"].data
    min_x: f32 = -TILE_X/2 + 0.5
    for id in 0..<len(data){
        if data[id]>0{
            j = i32(id/10)
            i = i32(id) - j*10
            x = min_x + f32(i*1.0)
            y = 0.5
            z = min_x + f32(j*1.0)
            flame := Animation_To_Model{
                frames = game.flames,
                position = {x, y, z},
                animation_frame_length = 0.1,
                animation_current_frame = 0,
                run_frame_timer = 0.0,
            }
            append(&game.flame_animations, flame)
        }
    } 
}

game_defer_delete :: proc(game: Game){
    defer delete(game.map_data1.layers)
    defer delete(game.level1)

    defer delete(game.map_data2.layers)
    defer delete(game.level2)

    defer delete(game.walls_bb)
    defer delete(game.doors_bb)

    defer delete(game.flame_animations)
    defer delete(game.flames)
}