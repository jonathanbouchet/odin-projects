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

game_started: bool

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

restart :: proc(paddle: ^Paddle, ball: ^Ball){
    set_paddle_position(paddle, rl.Vector2{SCREEN_SIZE/2 - PADDLE_WIDTH/2, PADDLE_POS_Y})
    set_ball_position(ball, rl.Vector2{SCREEN_SIZE/2, BALL_START_Y})
    game_started = false
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

    // paddle := Paddle{position=rl.Vector2{SCREEN_SIZE/2 - PADDLE_WIDTH/2, PADDLE_POS_Y}, velocity=rl.Vector2{0, 0}}
    paddle := Paddle{position=rl.Vector2{0, 0}, velocity=rl.Vector2{0, 0}}
    // direction is set in restart()
    // restart(&paddle)
    // ball := Ball{position=rl.Vector2{SCREEN_SIZE/2, BALL_START_Y}, velocity=rl.Vector2{0, 0}}
    ball := Ball{}
    restart(&paddle, &ball)


    for !rl.WindowShouldClose(){
        // logic
        // dt := rl.GetFrameTime()
        dt: f32
        if !game_started{
            if rl.IsKeyPressed(.SPACE){
                set_ball_direction(&ball, rl.Vector2{0, 1})
                game_started = true
            }
        }else{
            dt = rl.GetFrameTime()
            set_paddle_direction(&paddle)
            move_paddle(&paddle, dt)
            move_ball(&ball, dt)
        }

        // update
        // set_paddle_direction(&paddle)
        // move_paddle(&paddle, dt)

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
        rl.DrawCircleV(ball.position, BALL_RADIUS, rl.RED)

        if DEBUG {
            draw_debug(zoom = camera.zoom )
        }
        
        rl.EndMode2D()
        rl.EndDrawing()
    }
}