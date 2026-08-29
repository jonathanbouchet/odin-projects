// this is a window template for a raylib app
package main

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

WIDTH :: 600
HEIGTH :: 600
FPS :: 60
NAME :: "platformer"
BACKGROUND :: rl.Color{0, 0, 28, 255}
PLAYER_SIZE :: 64
PLAYER_COLOR :: rl.Color{76, 53, 83, 255}
PLAYER_SPEED :: 100
DEBUG :: true

bool_to_32 :: proc(value: bool) -> f32 {
    if value {
        return 1.0
    } else{
        return -1.0
    }
}

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
    rl.SetConfigFlags({.VSYNC_HINT})
    rl.InitWindow(WIDTH, HEIGTH, NAME)
    defer rl.CloseWindow()
    // rl.SetWindowState({.WINDOW_RESIZABLE})
    rl.SetTargetFPS(FPS)

    player_pos := rl.Vector2{WIDTH/2 - PLAYER_SIZE/2, HEIGTH/2 - PLAYER_SIZE/2}
    player_velocity: rl.Vector2

    for !rl.WindowShouldClose(){
        // logic
        dt := rl.GetFrameTime()

        // update
        player_velocity.x = (bool_to_32(rl.IsKeyDown(.RIGHT)) - bool_to_32(rl.IsKeyDown(.LEFT))) * PLAYER_SPEED
        player_pos += player_velocity * dt
        // if rl.IsKeyDown(.LEFT){
        //     player_pos.x -= 10
        // }else if rl.IsKeyDown(.RIGHT){
        //     player_pos.x += 10
        // }

        // rendering
        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND)
        rl.DrawRectangleV(player_pos, PLAYER_SIZE, PLAYER_COLOR)
        if DEBUG {
            draw_debug()
        }
        rl.EndDrawing()
    }
}

