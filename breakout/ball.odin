package breakout

import rl "vendor:raylib"

BALL_SPEED :: 50
BALL_RADIUS :: 5
BALL_START_Y :: 160

Ball :: struct {
    position: rl.Vector2,
    velocity: rl.Vector2
}

set_ball_position :: proc(ball: ^Ball, pos: rl.Vector2){
    ball.position = pos
}

set_ball_direction :: proc(ball: ^Ball, vel: rl.Vector2) {
    ball.velocity = vel
}

move_ball :: proc(ball: ^Ball, dt: f32) {
    ball.position += ball.velocity * dt * BALL_SPEED
}

