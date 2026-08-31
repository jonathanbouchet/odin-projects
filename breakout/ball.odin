package breakout

import rl "vendor:raylib"

BALL_SPEED :: 50
BALL_RADIUS :: 10
BALL_START_Y :: 160

Ball :: struct {
    position: rl.Vector2,
    velocity: rl.Vector2
}

