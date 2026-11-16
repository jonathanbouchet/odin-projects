package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

BACKGROUND :: rl.Color{0, 0, 28, 255}
GREEN :: rl.Color{57, 255, 20, 255}
WIDTH :: 600
HEIGHT :: 600
SIZE :: 10

Point_Screen :: struct{
    x: f32,
    y: f32,
}

Point_Window :: struct {
    x: f32,
    y: f32,
}

convert_screen_game :: proc(a: Point_Screen) -> Point_Window {
    return {
        x = (a.x + 1) / 2 * WIDTH - SIZE / 2,
        y = (1 - (a.y + 1) / 2) * HEIGHT - SIZE / 2
    }
} 

main :: proc(){
    rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})
    rl.InitWindow(WIDTH, HEIGHT, "projection 3D")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose(){
        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND)

        rl.DrawLineV(rl.Vector2{0, HEIGHT/2}, {WIDTH, HEIGHT/2}, rl.RED)
        rl.DrawLineV(rl.Vector2{WIDTH/2, 0}, {WIDTH/2, HEIGHT}, rl.RED)
        rl.EndDrawing()
    }
}