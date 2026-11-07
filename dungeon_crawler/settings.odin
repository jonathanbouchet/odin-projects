package main

import rl "vendor:raylib"

Settings :: struct {
    WIDTH: i32,
    HEIGHT: i32,
    WIDTH_UI: i32,
    WIDTH_FULL: i32,
    HEIGHT_FULL: i32,
    FPS: i32,
    BACKGROUND: rl.Color,
    BACKGROUND_BLACK: rl.Color,
    BACKGROUND_UI: rl.Color,
    OUTLINE_UI: rl.Color,
    GREEN: rl.Color,
    TILE_X: i32,
    TILE_Z: i32,
    TILE_Y: i32,
}

set_game :: proc() -> Settings {
    return {
        WIDTH = 640,
        HEIGHT = 400,
        WIDTH_UI = 160,
        WIDTH_FULL = 800,
        HEIGHT_FULL= 400,
        FPS = 60,
        BACKGROUND = rl.Color{0, 0, 28, 255},
        BACKGROUND_BLACK = rl.Color{20, 20, 20, 255 }, // light black
        BACKGROUND_UI = rl.Color{46, 34, 47, 255},
        OUTLINE_UI = rl.Color{122, 48, 69, 255},
        GREEN = rl.Color{57, 255, 20, 255},
        TILE_X = 10,
        TILE_Z = 10,
        TILE_Y = 2,
    }
}