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

Player :: struct {
    position: rl.Vector2,
    velocity: rl.Vector2
}

set_direction :: proc(player: ^Player) {
    player.velocity.x = 
        (bool_to_32(rl.IsKeyDown(.RIGHT)) - bool_to_32(rl.IsKeyDown(.LEFT))) * PLAYER_SPEED
}

move_player :: proc(player: ^Player, dt: f32) {
    player.position += player.velocity * dt
}

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
    rl.SetTargetFPS(FPS)

    player := Player{position=rl.Vector2{WIDTH/2 - PLAYER_SIZE/2, HEIGTH/2 - PLAYER_SIZE/2}, velocity={}}

    for !rl.WindowShouldClose(){
        // logic
        dt := rl.GetFrameTime()

        // update
        set_direction(&player)
        move_player(&player, dt)

        // rendering
        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND)
        rl.DrawRectangleV(player.position, PLAYER_SIZE, PLAYER_COLOR)
        if DEBUG {
            draw_debug()
        }
        rl.EndDrawing()
    }
}

