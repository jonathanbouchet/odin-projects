package breakout

import rl "vendor:raylib"

PADDLE_WIDTH :: 50
PADDLE_HEIGHT :: 10
PADDLE_POS_Y :: 260
PADDLE_SPEED :: 200

bool_to_32 :: proc(value: bool) -> f32 {
    if value {
        return 1.0
    } else{
        return -1.0
    }
}

Paddle :: struct {
    position: rl.Vector2,
    velocity: rl.Vector2
}

set_paddle_position :: proc(paddle: ^Paddle, pos: rl.Vector2){
    paddle.position = pos
}

set_paddle_direction :: proc(paddle: ^Paddle) {
    paddle.velocity.x = 
        (bool_to_32(rl.IsKeyDown(.RIGHT)) - bool_to_32(rl.IsKeyDown(.LEFT))) * PADDLE_SPEED
}

move_paddle :: proc(paddle: ^Paddle, dt: f32) {
    paddle.position += paddle.velocity * dt
    paddle.position.x = clamp(paddle.position.x, 0, SCREEN_SIZE - PADDLE_WIDTH)
}
