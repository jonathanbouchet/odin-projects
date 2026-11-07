package main

import "core:mem"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

WIDTH :: 640
HEIGHT :: 400
WIDTH_UI :: 160
WIDTH_FULL :: 800
HEIGHT_FULL:: 400
FPS :: 60
BACKGROUND :: rl.Color{0, 0, 28, 255}
BACKGROUND_BLACK :: rl.Color{20, 20, 20, 255 } // light black
BACKGROUND_UI :: rl.Color{46, 34, 47, 255}
OUTLINE_UI :: rl.Color{122, 48, 69, 255}
GREEN :: rl.Color{57, 255, 20, 255}
TILE_X :: 10
TILE_Z :: 10
TILE_Y :: 2

draw_debug :: proc(player: Player) {
    /*
    various "debug" utils:
    - draw the FPS number
    - draw lines, h and v, representing the mid-screen
    */
    player_colliding_str := strings.clone_to_cstring(fmt.tprintf("is colliding: %v", player.is_colliding))
    defer delete(player_colliding_str)
    player_pos_str := strings.clone_to_cstring(fmt.tprintf("X:%.2f, Z:%.2f", player.position.x, player.position.z))
    defer delete(player_pos_str)

    rl.DrawFPS(0, 0)
    rl.DrawText(player_pos_str, 0, 20, 20, GREEN)
    rl.DrawText(player_colliding_str, 0, 40, 20, rl.RED if player.is_colliding else GREEN)
    rl.DrawLineV(rl.Vector2{0, HEIGHT/2}, {WIDTH, HEIGHT/2}, GREEN)
    rl.DrawLineV(rl.Vector2{WIDTH/2, 0}, {WIDTH/2, HEIGHT}, GREEN)
}

main :: proc() {
    tracking: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking)

    defer {
        fmt.println("Memory statistics:")
        fmt.printfln("  Current:   %d bytes", tracking.current_memory_allocated)
        fmt.printfln("  Peak:      %d bytes", tracking.peak_memory_allocated)
        fmt.printfln("  Allocated: %d bytes total", tracking.total_memory_allocated)
        fmt.printfln("  Freed:     %d bytes total", tracking.total_memory_freed)
        fmt.printfln("  Allocations: %d", tracking.total_allocation_count)
        fmt.printfln("  Frees:       %d", tracking.total_free_count)

        if len(tracking.allocation_map) > 0 {
            fmt.eprintf("\nUnfreed allocations: %d\n", len(tracking.allocation_map))

            for _, entry in tracking.allocation_map {
                fmt.eprintf(
                    "  %d bytes allocated at %v\n",
                    entry.size,
                    entry.location,
                )
            }
        }

        if len(tracking.bad_free_array) > 0 {
            fmt.eprintf(
                "\nIncorrect frees: %d\n",
                len(tracking.bad_free_array),
            )

            for entry in tracking.bad_free_array {
                fmt.eprintf(
                    "  %p freed at %v\n",
                    entry.memory,
                    entry.location,
                )
            }
        }

        mem.tracking_allocator_destroy(&tracking)
    }
    settings := set_game()
    rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})
    rl.InitWindow(WIDTH_FULL, HEIGHT_FULL, "dungeon")
    defer rl.CloseWindow()
    rl.SetTargetFPS(FPS)

    game := game_init()
    game_load(&game)

    fmt.printfln("layers from game: %v", game.level1)

    defer delete(game.map_data1.layers)
    defer delete(game.level1)
    defer delete(game.walls_bb)
    fmt.printfln("wall bounding boxes: %v", game.walls_bb[:])

    // flames := make_model_from_animations(
    //     path="assets/textures/flame/frame_00", 
    //     start_anim=0, 
    //     max_anim=4,
    //     mesh_cube = [3]f32{1.0, 1.0, 0.0001},
    // )
    // defer delete(flames)

    // num_flames := len(game.level1["PROPS"].data)
    // flames_animation := make([dynamic]Animation_To_Model, 0, num_flames)
    // defer delete(flames_animation)

    // i, j: i32
    // x, y, z: f32
    // data := game.level1["PROPS"].data
    // min_x: f32 = -TILE_X/2 + 0.5
    // for id in 0..<len(data){
    //     if data[id]>0{
    //         j = i32(id/10)
    //         i = i32(id) - j*10
    //         x = min_x + f32(i*1.0)
    //         y = 0.5
    //         z = min_x + f32(j*1.0)
    //         flame := Animation_To_Model{
    //             frames = flames,
    //             position = {x, y, z},
    //             animation_frame_length = 0.1,
    //             animation_current_frame = 0,
    //             run_frame_timer = 0.0,
    //         }
    //         append(&flames_animation, flame)
    //     }
    // } 

    // coins := make_model_from_animations(
    //     path="assets/textures/silver_coin/", 
    //     start_anim=1, 
    //     max_anim=6,
    //     // path="assets/textures/coin/frame_", 
    //     // start_anim=1, 
    //     // max_anim=7,
    //     mesh_cube = [3]f32{0.5, 0.5, 0.0001},
    // )
    // defer delete(coins)

    // num_coins := len(game.level1["COINS"].data)
    // coins_animation := make([dynamic]Animation_To_Model, 0, num_coins)
    // defer delete(coins_animation)

    // // i, j: i32
    // // x, y, z: f32
    // data = game.level1["COINS"].data
    // // min_x: f32 = -TILE_X/2 + 0.5
    // for id in 0..<len(data){
    //     if data[id]>0{
    //         j = i32(id/10)
    //         i = i32(id) - j*10
    //         x = min_x + f32(i*1.0)
    //         y = 0.5
    //         z = min_x + f32(j*1.0)
    //         coin := Animation_To_Model{
    //             frames = coins,
    //             position = {x, y, z},
    //             animation_frame_length = 0.1,
    //             animation_current_frame = 0,
    //             run_frame_timer = 0.0,
    //         }
    //         append(&coins_animation, coin)
    //     }
    // } 

    // props_bb := make_boundary_boxes(
    //     texture_layer = game.level1["COINS"]^,
    //     width = 1.0,
    //     height = 1.0,
    //     depth = 1.0,
    // )
    // defer delete(props_bb)

    defer delete(game.doors_bb)

    game.player = Player{
        position = rl.Vector3{0, 0, 4},
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

    view_width := settings.WIDTH
    view_height := settings.HEIGHT

    game_view := rl.LoadRenderTexture(i32(view_width), i32(view_height))
    defer rl.UnloadRenderTexture(game_view)

    ui_rect := rl.Rectangle{f32(view_width), 0, f32(WIDTH_UI), HEIGHT}
    // hearts:= [3]rl.Texture{
    //     rl.LoadTexture("assets/textures/Heart_Full_64.png"),
    //     rl.LoadTexture("assets/textures/Heart_Half_64.png"),
    //     rl.LoadTexture("assets/textures/Heart_Empty_64.png"),
    // }

    rl.DisableCursor() 

    for !rl.WindowShouldClose() {
        // update
        update_player(&game.player, &game.camera, game.walls_bb)

        // render
        rl.BeginTextureMode(game_view)
        rl.ClearBackground(BACKGROUND_BLACK)
        rl.BeginMode3D(game.camera)

        draw_game(game)

        // for pr in props_bb{
        //     center := (pr.max + pr.min) / 2
        //     rl.DrawCubeWiresV(center, rl.Vector3{0.5, 1.0, 0.5}, GREEN)
        // }

        // for &fl in flames_animation{
        //     draw_animation_model(&fl)
        // }

        // for &co in coins_animation{
        //     draw_animation_model(&co)
        // }

        rl.EndMode3D()
        rl.EndTextureMode()

        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND_UI)

        // draw UI icons OUTSIDE mode3D
        // draw_button(heart_button)
        rl.DrawTextureRec(
            game_view.texture,
            rl.Rectangle{0, 0, f32(view_width), -f32(view_height)},
            rl.Vector2{0, 0},
            rl.WHITE,
        )

        // draw_ui_panels(ui_rect, hearts)

        rl.EndDrawing()
    }
}