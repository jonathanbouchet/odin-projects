package breakout

import "core:fmt"
import "core:mem"
import "core:math/rand"
import "core:math/linalg"
import rl "vendor:raylib"

SCREEN_SIZE :: 320
WIDTH :: 640
HEIGTH :: 640
FPS :: 30
NAME :: "breakout"
// BACKGROUND :: rl.Color{0, 0, 28, 255}
// BACKGROUND :: rl.Color{15, 15, 15, 255}
BACKGROUND :: rl.Color{ 150, 190, 220, 255 }
DEBUG :: true

game_started: bool
game_over: bool
score: int = 0
previous_score: int
accumulated_time: f32

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
    // rl.DrawLineV(rl.Vector2{0, HEIGTH/(2*zoom)}, {WIDTH, HEIGTH/(2*zoom)}, rl.Color{57, 255, 20, 255})
    // rl.DrawLineV(rl.Vector2{WIDTH/(2 * zoom), 0}, {WIDTH/2/zoom, HEIGTH}, rl.Color{57, 255, 20, 255})
    rl.DrawLineV(rl.Vector2{0, HEIGTH/(2 * zoom)}, {WIDTH, HEIGTH/(2 * zoom)}, rl.BLACK)
    rl.DrawLineV(rl.Vector2{WIDTH/(2 * zoom), 0}, {WIDTH/2/zoom, HEIGTH}, rl.BLACK)
}

restart :: proc(paddle: ^Paddle, ball: ^Ball, blocks: ^Blocks, zoom: f32){
    set_paddle_position(paddle, rl.Vector2{SCREEN_SIZE/2 - PADDLE_WIDTH/2, PADDLE_POS_Y})
    ball_random_pos := rl.Vector2{rand.float32_range(f32(0), f32(WIDTH/zoom)), rand.float32_range(f32(200/zoom), f32(HEIGTH/2/zoom))} 
    set_ball_position(ball, ball_random_pos)
    game_started = false
    previous_score = score
    score = 0
    // initialize all blocks to false at the start of each round
    for i in 0..<NUM_BLOCKS_X{
        for j in 0..<NUM_BLOCKS_Y{
            blocks.status[i][j] = true
        }
    }
}

reflect :: proc(dir, normal: rl.Vector2) -> rl.Vector2{
    new_dir := linalg.reflect(dir, linalg.normalize(normal))
    return linalg.normalize(new_dir)
}

check_collision_paddle_ball :: proc(paddle: ^Paddle, ball: ^Ball, previous_ball_pos: rl.Vector2){
    paddle_rect := rl.Rectangle{paddle.position.x, paddle.position.y, PADDLE_WIDTH, PADDLE_HEIGHT}
    ball_center := ball.position
    ball_radius := f32(BALL_RADIUS)
    if rl.CheckCollisionCircleRec(center=ball_center, radius=ball_radius, rec=paddle_rect){
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
            ball_direction := reflect(ball.velocity, collision_normal)
            set_ball_direction(ball=ball, vel=ball_direction)
        }
    }
}

check_collision_walls_ball :: proc(ball: ^Ball){
    if ball.position.x + BALL_RADIUS > SCREEN_SIZE{
        collision_normal := rl.Vector2{-1, 0}
        ball_direction := reflect(ball.velocity, collision_normal)
        set_ball_position(ball, rl.Vector2{SCREEN_SIZE - BALL_RADIUS, ball.position.y })
        set_ball_direction(ball=ball, vel=ball_direction)
    }
    if ball.position.x -BALL_RADIUS < 0{
        collision_normal := rl.Vector2{1, 0}
        ball_direction := reflect(ball.velocity, collision_normal)
        set_ball_position(ball, rl.Vector2{BALL_RADIUS, ball.position.y })
        set_ball_direction(ball=ball, vel=ball_direction)
    }
    if ball.position.y - BALL_RADIUS< 0{
        collision_normal := rl.Vector2{0, 1}
        ball_direction := reflect(ball.velocity, collision_normal)
        set_ball_position(ball, rl.Vector2{ball.position.x, BALL_RADIUS })
        set_ball_direction(ball=ball, vel=ball_direction)
    }
}

check_miss_paddle_ball :: proc(ball: Ball) -> bool{
    if ball.position.y > SCREEN_SIZE + BALL_RADIUS{
        game_over = true
        return true
    }
    return false
}

check_collisions_blocks_ball :: proc(blocks: ^Blocks, ball: ^Ball, previous_ball_pos: rl.Vector2){
    block_x_loop: for i in 0..<NUM_BLOCKS_X{
        for j in 0..<NUM_BLOCKS_Y{
            if blocks.status[i][j] == false{
                continue
            }
            block_rect := get_block_rect(i, j)
            if rl.CheckCollisionCircleRec(ball.position, BALL_RADIUS, block_rect){
                collision_normal: rl.Vector2
                if previous_ball_pos.y < block_rect.y{
                    collision_normal += {0, -1}
                }
                if previous_ball_pos.y > block_rect.y + BLOCK_HEIGHT{
                    collision_normal += {0, 1}
                }
                if previous_ball_pos.x < block_rect.x{
                    collision_normal += {-1, 0}
                }
                if previous_ball_pos.x > block_rect.x + BLOCK_WIDTH{
                    collision_normal += {1, 0}
                }
                // if block_exists(i + int(collision_normal.x),j, blocks.status[i][j]){
                //     collision_normal.x = 0
                // }
                // if block_exists(i, j + int(collision_normal.y), blocks.status[i][j]){
                //     collision_normal.y = 0
                // }
                if collision_normal != 0{
                    ball_direction := reflect(ball.velocity, collision_normal)
                    set_ball_direction(ball=ball, vel=ball_direction)
                }
                blocks.status[i][j] = false
                row_color:= row_colors[j]
                score += block_color_scores[row_color]
                break block_x_loop
            }
        }
    }
}

draw_blocks :: proc(blocks: Blocks){
    for i in 0..<NUM_BLOCKS_X{
        for j in 0..<NUM_BLOCKS_Y{
            if blocks.status[i][j] == false{
                continue
            }
            block_rect := get_block_rect(i, j)

            top_left := rl.Vector2{block_rect.x, block_rect.y}
            top_right := rl.Vector2{block_rect.x + block_rect.width, block_rect.y}
            bottom_left := rl.Vector2{block_rect.x, block_rect.y + block_rect.height}
            bottom_right := rl.Vector2{block_rect.x + block_rect.width, block_rect.y + block_rect.height}

            rl.DrawRectangleRec(block_rect, block_color_values[row_colors[j]])
            rl.DrawLineEx(top_left, top_right, 1, rl.Color{255, 255, 150, 100})
            rl.DrawLineEx(top_left, bottom_left, 1, rl.Color{255, 255, 150, 100})
            rl.DrawLineEx(top_right, bottom_right, 2, rl.Color{0, 0, 50, 100})
            rl.DrawLineEx(bottom_left, bottom_right, 2, rl.Color{0, 0, 50, 100})
        }
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

     ball_texture := rl.LoadTexture("ball.png")
     paddle_texture := rl.LoadTexture("paddle.png")

    // paddle := Paddle{position=rl.Vector2{SCREEN_SIZE/2 - PADDLE_WIDTH/2, PADDLE_POS_Y}, velocity=rl.Vector2{0, 0}}
    paddle := Paddle{position=rl.Vector2{0, 0}, velocity=rl.Vector2{0, 0}}
    // direction is set in restart()
    // restart(&paddle)
    // ball := Ball{position=rl.Vector2{SCREEN_SIZE/2, BALL_START_Y}, velocity=rl.Vector2{0, 0}}
    ball := Ball{}
    blocks := Blocks{}
    restart(paddle=&paddle, ball=&ball, blocks=&blocks, zoom=f32(rl.GetScreenHeight()) / SCREEN_SIZE)


    for !rl.WindowShouldClose(){
        // logic
        // dt := rl.GetFrameTime()
        dt: f32
        DT :: 1.0 / 60.0
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
            accumulated_time += rl.GetFrameTime()
            set_paddle_direction(&paddle)
            move_paddle(&paddle, dt)
            previous_ball_pos := ball.position // we get the previous ball position before updating the current one
            move_ball(&ball, dt)
            check_collision_walls_ball(ball=&ball)
            check_collision_paddle_ball(ball=&ball, paddle=&paddle, previous_ball_pos=previous_ball_pos)
            check_collisions_blocks_ball(blocks=&blocks, ball=&ball, previous_ball_pos=previous_ball_pos)
            if check_miss_paddle_ball(ball){
                restart(paddle=&paddle, ball=&ball, blocks=&blocks, zoom=f32(rl.GetScreenHeight()) / SCREEN_SIZE)
            }
        }

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
        // draw paddle
        // rl.DrawRectangleRec(paddle_rect, rl.Color{0, 0, 28, 255}) // this is using simple Rectangle with a color
        rl.DrawTextureV(paddle_texture, get_paddle_position(paddle), rl.WHITE)
        // draw blocks
        draw_blocks(blocks=blocks)
        // draw ball
        // rl.DrawCircleV(ball.position, BALL_RADIUS, rl.RED) //this is using a simple circle
        rl.DrawTextureV(ball_texture, get_ball_position(ball), rl.WHITE)

        if DEBUG {
            draw_debug(zoom = camera.zoom)
        }

        score_text := fmt.ctprint(score) 
        // this allocates a temporary allocator(memory), as in c-string "t"emporary
        // needs to be freed at the end of the frame
        rl.DrawText(score_text, i32(WIDTH / camera.zoom) - 20, 5, 10, rl.WHITE)
        if game_over && !game_started{
            game_over_text := fmt.ctprintf("SCORE: %v. RESET: SPACE", previous_score)
            game_over_text_width := rl.MeasureText(game_over_text, 10)
            rl.DrawText(
                game_over_text, 
                i32(WIDTH/2/camera.zoom) - i32(game_over_text_width/2/i32(camera.zoom)), 
                i32(HEIGTH/2/camera.zoom), 
                10, 
                rl.WHITE
            )
        }
        
        rl.EndMode2D()
        rl.EndDrawing()
        free_all(context.temp_allocator)
    }
}