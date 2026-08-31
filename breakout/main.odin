package breakout

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

SCREEN_SIZE :: 320
WIDTH :: 640
HEIGTH :: 640
FPS :: 60
NAME :: "breakout"
// BACKGROUND :: rl.Color{0, 0, 28, 255}
BACKGROUND :: rl.Color{15, 15, 15, 255}
DEBUG :: true

show_memory :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer {
        for _, entry in track.allocation_map {
            fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
        }
        for entry in track.bad_free_array {
            fmt.eprintf("%v bad free\n", entry.location)
        }
        mem.tracking_allocator_destroy(&track)
    }
}

draw_debug :: proc(zoom: f32) {
    rl.DrawFPS(0, 0)
    rl.DrawLineV(rl.Vector2{0, HEIGTH/(2*zoom)}, {WIDTH, HEIGTH/(2*zoom)}, rl.Color{57, 255, 20, 255})
    rl.DrawLineV(rl.Vector2{WIDTH/(2 * zoom), 0}, {WIDTH/2/zoom, HEIGTH}, rl.Color{57, 255, 20, 255})
}

main :: proc() {
    if DEBUG {
        show_memory()
    }
    fmt.println("template for Raylib game")
    rl.SetConfigFlags({.VSYNC_HINT})
    rl.InitWindow(WIDTH, HEIGTH, NAME)
    defer rl.CloseWindow()
    rl.SetTargetFPS(FPS)

    paddle := Paddle{position=rl.Vector2{0, PADDLE_POS_Y}, velocity=rl.Vector2{0, 0}}

    for !rl.WindowShouldClose(){
        // logic
        dt := rl.GetFrameTime()

        // update
        set_direction(&paddle)
        move_player(&paddle, dt)

        // rendering
        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND)

        // camera
        camera := rl.Camera2D{
            zoom = f32(rl.GetScreenHeight()) / SCREEN_SIZE
        }
        rl.BeginMode2D(camera)
        paddle_rect := rl.Rectangle{
            paddle.position.x, paddle.position.y, PADDLE_WIDTH, PADDLE_HEIGHT
        }
        rl.DrawRectangleRec(paddle_rect, rl.Color{0, 0, 28, 255})

        if DEBUG {
            draw_debug(zoom = camera.zoom )
        }
        
        rl.EndMode2D()
        rl.EndDrawing()
    }
}