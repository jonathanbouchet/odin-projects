package breakout

import rl "vendor:raylib"

NUM_BLOCKS_X :: 10
NUM_BLOCKS_Y :: 8
BLOCK_WIDTH :: 28
BLOCK_HEIGHT :: 8

Blocks :: struct{
    status: [NUM_BLOCKS_X][NUM_BLOCKS_Y]bool,
}

block_color :: enum{
        YELLOW,
        GREEN,
        ORANGE,
        RED,
}

row_colors:= [NUM_BLOCKS_Y]block_color{
    .RED,
    .RED,
    .ORANGE,
    .ORANGE,
    .GREEN,
    .GREEN,
    .YELLOW,
    .YELLOW
}
//an enum array
block_color_values := [block_color]rl.Color{
    .YELLOW = {253, 249, 159, 255},
    .RED = {250, 90, 85, 255},
    .GREEN = {180, 245, 190, 255},
    .ORANGE = {170, 120, 250, 255},
}

get_block_rect :: proc(i, j: int) -> rl.Rectangle{
    return {
        f32(20 + i * BLOCK_WIDTH),
        f32(40 + j * BLOCK_HEIGHT),
        BLOCK_WIDTH,
        BLOCK_HEIGHT
    }
}