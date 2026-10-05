package main

import "core:mem"
import "core:fmt"
import rl "vendor:raylib"

WIDTH :: 600
HEIGHT :: 600
FPS :: 60
BACKGROUND :: rl.Color{0, 0, 28, 255}
// BACKGROUND :: rl.Color{15, 15, 15, 255}
// BACKGROUND :: rl.Color{ 150, 190, 220, 255 }

draw_debug :: proc() {
    rl.DrawFPS(0, 0)
    rl.DrawLineV(rl.Vector2{0, HEIGHT/2}, {WIDTH, HEIGHT/2}, rl.Color{57, 255, 20, 255})
    rl.DrawLineV(rl.Vector2{WIDTH/2, 0}, {WIDTH/2, HEIGHT}, rl.Color{57, 255, 20, 255})
}

main :: proc() {
    tracking: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking)

    defer {
        fmt.printfln(
            "Current memory: %d bytes, peak memory: %d bytes",
            tracking.current_memory_allocated,
            tracking.peak_memory_allocated,
        )

        if len(tracking.allocation_map) > 0 {
            fmt.eprintln("Unfreed allocations:")

            for _, entry in tracking.allocation_map {
                fmt.eprintf(
                    "- %d bytes @ %v\n",
                    entry.size,
                    entry.location,
                )
            }
        }

        mem.tracking_allocator_destroy(&tracking)
    }
    rl.InitWindow(WIDTH, HEIGHT, "character animation")
    defer rl.CloseWindow()
    rl.SetTargetFPS(FPS)
    
    textures:= make(map[string][dynamic]rl.Texture)
    textures["idle"] = load_textures_from_directory("assets/player/idle")
    textures["run"] = load_textures_from_directory("assets/player/run")
    defer unload_textures(&textures)

    for key, value in textures {
        fmt.printfln("key: %v, value: %v", key, value)
    }

    // player
    player := Player{
        position = {f32(WIDTH/2 - textures["idle"][0].width/2), f32(HEIGHT/2 - textures["idle"][0].height/2)}, 
        speed = 20, 
        state = .IDLE}

    for !rl.WindowShouldClose() {
        // update
        // render
        rl.BeginDrawing(); defer rl.EndDrawing()
        draw_player(player, textures["idle"][0])
        rl.ClearBackground(BACKGROUND)
        draw_debug()
    }
}