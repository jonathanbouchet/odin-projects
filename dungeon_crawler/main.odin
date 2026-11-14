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

draw_debug :: proc(game: Game) {
    /*
    various "debug" utils:
    - draw the FPS number
    - draw lines, h and v, representing the mid-screen
    */
    player_colliding_str := strings.clone_to_cstring(fmt.tprintf("is colliding: %v", game.player.is_colliding))
    defer delete(player_colliding_str)
    player_pos_str := strings.clone_to_cstring(fmt.tprintf("X:%.2f, Z:%.2f", game.player.position.x, game.player.position.z))
    defer delete(player_pos_str)
    game_level_str := strings.clone_to_cstring(fmt.tprintf("LEVEL:%d", game.current_level_id))
    defer delete(game_level_str)
    player_stats_str := strings.clone_to_cstring(fmt.tprintf("HP:%d, COINS: %v", game.player.HP, game.player.coins_collected))
    defer delete(player_stats_str)

    rl.DrawFPS(0, 0)
    rl.DrawText(player_pos_str, 0, 20, 20, GREEN)
    rl.DrawText(player_colliding_str, 0, 40, 20, rl.RED if game.player.is_colliding else GREEN)
    rl.DrawText(player_stats_str, 0, 60, 20, GREEN)
    rl.DrawText(game_level_str, 0, 80, 20, GREEN)
    rl.DrawLineV(rl.Vector2{0, HEIGHT/2}, {WIDTH, HEIGHT/2}, GREEN)
    rl.DrawLineV(rl.Vector2{WIDTH/2, 0}, {WIDTH/2, HEIGHT}, GREEN)
}

main :: proc() {
    // entry point
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

    // ui_rect := rl.Rectangle{f32(view_width), 0, f32(WIDTH_UI), HEIGHT}
    // hearts:= [3]rl.Texture{
    //     rl.LoadTexture("assets/textures/Heart_Full_64.png"),
    //     rl.LoadTexture("assets/textures/Heart_Half_64.png"),
    //     rl.LoadTexture("assets/textures/Heart_Empty_64.png"),
    // }

    rl.DisableCursor() 

    fmt.printfln("game.view_width: %v, game.view_height: %v", game.view_width, game.view_height)

    for !rl.WindowShouldClose() {
        // update
        game_update(&game)

        // render
        rl.BeginTextureMode(game.view)
        rl.ClearBackground(BACKGROUND_BLACK)
        rl.BeginMode3D(game.camera)

        game_draw(game)

        rl.EndMode3D()
        rl.EndTextureMode()

        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND_UI)

        // draw UI icons OUTSIDE mode3D
        // draw_button(heart_button)
        game_draw_ui_container(game)

        // draw_ui_panels(ui_rect, hearts)
        if game.debug{
            draw_debug(game)
        }

        rl.EndDrawing()
    }
    game_defer_delete(game)
}