package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

Game :: struct {
    view_width: i32,
    view_height: i32,
    view: rl.RenderTexture2D,
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
    num_flames_arr: [2]i32, // per level
    flame_animations_arr: [2][dynamic]Animation_To_Model, // per level
}

game_init :: proc() -> Game{
    game: Game
    game.view_width = WIDTH
    game.view_height = HEIGHT
    game.view = rl.LoadRenderTexture(i32(game.view_width), i32(game.view_height))
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
    fmt.printfln("# of layers in map 1: %v", len(game.map_data1.layers))
    game.level1 = extract_all_layers(game.map_data1)

    game.map_data2 = read_input_data("assets/maps/test3_10x10.tmj", Map_Data)
    fmt.printfln("# of layers in map 2: %v", len(game.map_data2.layers))
    game.level2 = extract_all_layers(game.map_data2)

    game.current_level_id = 1
    game.current_level = &game.level1

    game.wall = load_and_make_model("assets/textures/wall_minimalist_32x32_v3.png", rl.Vector3{1.0, 1.0, 1.0})
    game.floor = load_and_make_model("assets/textures/floor_minimalist_32x32.png", rl.Vector3{1.0, 0.01, 1.0})
    game.door = load_and_make_model("assets/textures/door_minimalist_32x32.png", rl.Vector3{1.0, 1.0, 0.0001})
    game.flames, game.num_flames_arr, game.flame_animations_arr = 
        game_make_level_animations(game=game, path="assets/textures/flame2/Sprite-000", start_anim=1, max_anim=7, layer="PROPS")
    game_make_boundingboxes(game)

    game.player = Player{
        position = rl.Vector3{-1, 0, 5},
        velocity = {},
        speed = 5,
        eyes = 1,
        yaw = 0.0,
        pitch = 0.0,
        sensitivity = 0.003,
        is_colliding = false,
    }

    game.camera = rl.Camera3D{
        up         = { 0.0, 1.0, 0.0 },  // Camera up vector (rotation towards target)
        target     = { 0.0, 1.0, 10.0},
        fovy       = 60.0,               // Camera field-of-view Y
        projection = .PERSPECTIVE,       // Camera projection type
    }
    game.debug = true
}

game_draw :: proc(game: Game){
    draw_floor_layer_from_map(game.current_level["FLOOR"]^, game.floor)
    draw_full_wall_from_layer(game.current_level["WALL"]^, game.wall)
    draw_doors_from_layer(game.current_level["DOORS"]^, game.door)
    for &fl in game.flame_animations_arr[game.current_level_id]{
        draw_animation_model(&fl, 1.0)
    }
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
    game.player.pitch = clamp_f32(game.player.pitch, -max_pitch, max_pitch)
    // to lock the mouse vertical movement
    // game.player.pitch = 0

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
    fmt.printfln("current level id: %v", game.current_level_id)
    fmt.printfln("current level data: %v", game.current_level)
    if game.current_level_id == 0{
        game.current_level_id = 1
        game.current_level = &game.level2
        // TO DO: need the door location for spawning the player

        // update the bb of the current level
        // clear existing bb before updating them
        // wrong: need to delete entirely because clear does not free the underlying heap-allocated memory
        // -> the capacity (cap()) remains intact
        delete(game.walls_bb)
        delete(game.doors_bb)
        game_make_boundingboxes(game)
    } else {
        game.current_level_id = 0
        game.current_level = &game.level1

        // clear existing bb before updating them
        delete(game.walls_bb)
        delete(game.doors_bb)
        game_make_boundingboxes(game)
    }
    fmt.printfln("after: current level id: %v", game.current_level_id)
    fmt.printfln("after: current level data: %v", game.current_level)
}

game_make_boundingboxes :: proc(game: ^Game){
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

game_make_level_animations :: proc(game: ^Game, path: string, start_anim: i32, max_anim: i32, layer: string) -> ([dynamic]rl.Model, [2]i32, [2][dynamic]Animation_To_Model){
    num_flames: [2]i32
    flame_animations: [2][dynamic]Animation_To_Model
    flames := make_model_from_animations(
        path=path, 
        start_anim=start_anim, 
        max_anim=max_anim,
        mesh_cube = [3]f32{1.0, 1.0, 0.0001},
    )
    for level_id in 0..<2{
        if level_id == 0{
            game.current_level_id = 0
            game.current_level = &game.level1
        } else{
            game.current_level_id = 1
            game.current_level = &game.level2
        }

        data := game.current_level["PROPS"].data
        tmp_num_flames: i32 = 0
        for id in 0..<len(data){
            if data[id] > 0 {
                    tmp_num_flames += 1
                }
            }
        num_flames[level_id] = tmp_num_flames
        animations := make([dynamic]Animation_To_Model, 0, num_flames[level_id])
        i, j: i32
        x, y, z: f32
        min_x: f32 = -TILE_X/2 + 0.5
        for id in 0..<len(data){
            if data[id]>0{
                j = i32(id/10)
                i = i32(id) - j*10
                x = min_x + f32(i*1.0)
                y = 0.5
                z = min_x + f32(j*1.0)
                flame := Animation_To_Model{
                    frames = flames,
                    position = {x, y, z},
                    animation_frame_length = 0.1,
                    animation_current_frame = 0,
                    run_frame_timer = 0.0,
                }
                append(&animations, flame)
            }
        }
        flame_animations[level_id] = animations 
    }
    // reset the current_level_id to 0
    // it has been overwriten when finding the data[id]>0
    game.current_level_id = 0
    game.current_level = &game.level1
    return flames, num_flames, flame_animations
}

game_defer_delete :: proc(game: Game){
    defer rl.UnloadRenderTexture(game.view)
    defer delete(game.map_data1.layers)
    defer delete(game.level1)

    defer delete(game.map_data2.layers)
    defer delete(game.level2)

    defer delete(game.walls_bb)
    defer delete(game.doors_bb)

    defer delete(game.flame_animations_arr[0])
    defer delete(game.flame_animations_arr[1])
    defer delete(game.flames)
}