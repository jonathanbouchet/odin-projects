// this is a window template for a raylib app
package main

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

WIDTH :: 600
HEIGTH :: 600
FPS :: 60
NAME :: "app"
BACKGROUND :: rl.Color{0, 0, 28, 255}
DEBUG :: true

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

draw_debug :: proc() {
    rl.DrawFPS(0, 0)
    rl.DrawLineV(rl.Vector2{0, HEIGTH/2}, {WIDTH, HEIGTH/2}, rl.Color{57, 255, 20, 255})
    rl.DrawLineV(rl.Vector2{WIDTH/2, 0}, {WIDTH/2, HEIGTH}, rl.Color{57, 255, 20, 255})
}

main :: proc() {
    if DEBUG {
        show_memory()
    }
    fmt.println("template for Raylib game")
    rl.InitWindow(WIDTH, HEIGTH, NAME)
    defer rl.CloseWindow()
    rl.SetWindowState({.WINDOW_RESIZABLE})
    rl.SetTargetFPS(FPS)
    for !rl.WindowShouldClose(){
        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND)
        if DEBUG {
            draw_debug()
        }
        rl.EndDrawing()
    }
}

