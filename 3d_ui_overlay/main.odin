package main

import "core:mem"
import "core:fmt"
import rl "vendor:raylib"

WIDTH_GAME :: 600
WIDTH_UI :: 200
WIDTH :: 800
HEIGHT :: 600
FPS_TARGET :: 60
BACKGROUND :: rl.Color{0, 0, 28, 255}
BACKGROUND_BLACK :: rl.Color{20, 20, 20, 255 } // light black
GREEN :: rl.Color{57, 255, 20, 255}

draw_debug :: proc() {
    /*
    various "debug" utils:
    - draw the FPS number
    - draw lines, h and v, representing the mid-screen
    */
    rl.DrawFPS(0, 0)
    rl.DrawLineV(rl.Vector2{0, HEIGHT/2}, {WIDTH, HEIGHT/2}, GREEN)
    rl.DrawLineV(rl.Vector2{WIDTH/2, 0}, {WIDTH/2, HEIGHT}, GREEN)
}

draw_ui_panels :: proc(ui_rect: rl.Rectangle, hearts: [3]rl.Texture) {
    // ui_rect := rl.Rectangle{600,0, 200, 600}
    rl.DrawRectangleLinesEx(ui_rect, 4, rl.RED)
    for i: i32 = 0; i< len(hearts); i+=1{
        rl.DrawTextureV(hearts[i], rl.Vector2{f32(600) + f32(i)*f32(hearts[i].width), 0}, rl.RAYWHITE)
    }
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
    rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})
    rl.InitWindow(WIDTH, HEIGHT, "dungeon")
    defer rl.CloseWindow()
    rl.SetTargetFPS(FPS_TARGET)

     camera := rl.Camera3D{
        position   = { 0.0, 10.0, 10.0 },
        target     = { 0.0, 0.0, 0.0 },
        up         = { 0.0, 1.0, 0.0 },
        fovy       = 60.0,
        projection = .PERSPECTIVE,
    }

    rl.DisableCursor()

    view_width := WIDTH_GAME
    view_height := HEIGHT

    game_view := rl.LoadRenderTexture(i32(view_width), i32(view_height))
    defer rl.UnloadRenderTexture(game_view)

    ui_rect := rl.Rectangle{f32(view_width), 0, f32(WIDTH_UI), HEIGHT}
    hearts:= [3]rl.Texture{
        rl.LoadTexture("Heart_Full_64.png"),
        rl.LoadTexture("Heart_Half_64.png"),
        rl.LoadTexture("Heart_Empty_64.png"),
    }

    for !rl.WindowShouldClose() {
        // update pass
        rl.UpdateCamera(&camera, .FIRST_PERSON)
        // render pass

        // 1st is the 3D scene into its own texture.
        rl.BeginTextureMode(game_view)
        rl.ClearBackground(BACKGROUND_BLACK)
        rl.BeginMode3D(camera)
        rl.DrawGrid(10, 2)
        rl.EndMode3D()
        rl.EndTextureMode()

        // Draw the whole screen: view first, then UI on top.
        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND)

        rl.DrawTextureRec(
            game_view.texture,
            rl.Rectangle{0, 0, f32(view_width), -f32(view_height)},
            rl.Vector2{0, 0},
            rl.WHITE,
        )

        draw_ui_panels(ui_rect, hearts)
        draw_debug()
        rl.EndDrawing()
    }
}