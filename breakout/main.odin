package breakout

import "core:fmt"
import "core:mem"
import "core:math/rand"
import "core:math/linalg"
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

restart :: proc(paddle: ^Paddle, ball: ^Ball, zoom: f32){
    set_paddle_position(paddle, rl.Vector2{SCREEN_SIZE/2 - PADDLE_WIDTH/2, PADDLE_POS_Y})
    ball_random_pos := rl.Vector2{rand.float32_range(f32(0), f32(WIDTH/zoom)), rand.float32_range(f32(0), f32(200/zoom))} 
    // set_ball_position(ball, rl.Vector2{SCREEN_SIZE/2, BALL_START_Y})
    set_ball_position(ball, ball_random_pos)
    game_started = false
}

check_collision_paddle_ball :: proc(paddle: ^Paddle, ball: ^Ball, previous_ball_pos: rl.Vector2){
    collision_normal: rl.Vector2
    if previous_ball_pos.y < paddle.position.y + PADDLE_HEIGHT{
        collision_normal = {0, -1}
        set_ball_position(ball, rl.Vector2{ball.position.x, paddle.position.y - BALL_RADIUS})
    }
    if previous_ball_pos.y > paddle.position.y + PADDLE_HEIGHT{
        collision_normal = {0, 1}
        set_ball_position(ball, rl.Vector2{ball.position.x, paddle.position.y + PADDLE_HEIGHT + BALL_RADIUS})
    }
    if previous_ball_pos.x < paddle.position.x{
        collision_normal = {-1, 0}
    }
    if previous_ball_pos.x > paddle.position.x + PADDLE_WIDTH{
        collision_normal = {1, 0}
    }
    if collision_normal != 0{
        ball_direction := linalg.normalize(linalg.reflect(ball.velocity, linalg.normalize(collision_normal)))
        set_ball_direction(ball=ball, vel=ball_direction)
    }

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
    restart(paddle=&paddle, ball=&ball, zoom=f32(rl.GetScreenHeight()) / SCREEN_SIZE)


    for !rl.WindowShouldClose(){
        // logic
        // dt := rl.GetFrameTime()
        dt: f32
        if !game_started{
            if rl.IsKeyPressed(.SPACE){
                // set_ball_direction(&ball, rl.Vector2{0, 1}) // set a constant direction
                paddle_mid_position := rl.Vector2{paddle.position.x + PADDLE_WIDTH/2, paddle.position.y}
                ball_position := ball.position
                ball_2_paddle := paddle_mid_position - ball_position 
                ball_direction_2_paddle := linalg.normalize(ball_2_paddle)
                set_ball_direction(ball=&ball, vel=ball_direction_2_paddle)
                game_started = true
            }
        }else{
            dt = rl.GetFrameTime()
            set_paddle_direction(&paddle)
            move_paddle(&paddle, dt)
            move_ball(&ball, dt)
            previous_ball_pos := ball.position
            // check_collision_paddle_ball(ball=&ball, paddle=&paddle, previous_ball_pos=previous_ball_pos)
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
            draw_debug(zoom = camera.zoom)
        }
        
        rl.EndMode2D()
        rl.EndDrawing()
    }
}