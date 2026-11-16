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

convert_screen_game :: proc(a: [2]f32) -> [2]f32 {
    tmp: [2]f32
    tmp[0] = (a[0] + 1) / 2 * WIDTH - SIZE / 2
    tmp[1] = (1 - (a[1] + 1) / 2) * HEIGHT - SIZE / 2
    return tmp
} 

project_point :: proc(a: [3]f32, dz: f32) -> [2]f32 {
    tmp : [2]f32
    t := a[2] + dz
    tmp[0] = a[0] / t
    tmp[1] = a[1] / t
    return tmp
}

draw_vertex :: proc(a: [2]f32) {
    rl.DrawRectangleV(a, rl.Vector2{SIZE, SIZE}, GREEN)
}

draw_vertices :: proc(points: [8]rl.Vector3, dz: f32) {
    for point in points{
        draw_vertex(convert_screen_game(project_point(point, dz)))
    }
}

main :: proc(){
    rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})
    rl.InitWindow(WIDTH, HEIGHT, "projection 3D")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    a := rl.Vector3{ 0.5,  0.5, 0.5}
    b := rl.Vector3{ 0.5, -0.5, 0.5}
    c := rl.Vector3{-0.5,  0.5, 0.5}
    d := rl.Vector3{-0.5, -0.5, 0.5}
    e := rl.Vector3{ 0.5,  0.5, -0.5}
    f := rl.Vector3{ 0.5, -0.5, -0.5}
    g := rl.Vector3{-0.5,  0.5, -0.5}
    h := rl.Vector3{-0.5, -0.5, -0.5}

    points:= [8]rl.Vector3{a, b, c, d, e, f, g, h}

    dz:= f32(1.0)
  
    for !rl.WindowShouldClose(){

        // update
        dt:= rl.GetFrameTime()
        dz += dt

        // render
        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND)

        draw_vertices(points, dz)

        rl.DrawLineV(rl.Vector2{0, HEIGHT/2}, {WIDTH, HEIGHT/2}, rl.RED)
        rl.DrawLineV(rl.Vector2{WIDTH/2, 0}, {WIDTH/2, HEIGHT}, rl.RED)
        rl.EndDrawing()
    }
}