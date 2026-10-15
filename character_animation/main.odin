package main

import "core:mem"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

WIDTH :: 600
HEIGHT :: 600
FPS :: 60
BACKGROUND :: rl.Color{0, 0, 28, 255}
// BACKGROUND :: rl.Color{15, 15, 15, 255}
// BACKGROUND :: rl.Color{ 150, 190, 220, 255 }

draw_debug :: proc(player: Player) {
    rl.DrawFPS(0, 0)
    rl.DrawLineV(rl.Vector2{0, HEIGHT/2}, {WIDTH, HEIGHT/2}, rl.Color{57, 255, 20, 255})
    rl.DrawLineV(rl.Vector2{WIDTH/2, 0}, {WIDTH/2, HEIGHT}, rl.Color{57, 255, 20, 255})
    player_state_string, ok := fmt.enum_value_to_string(player.state)
    if ok {
        player_state_cstring := strings.clone_to_cstring(player_state_string)
        defer delete(player_state_cstring)
        rl.DrawText(player_state_cstring, 0, 20, 20, rl.DARKGREEN)
    }
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
    rl.SetTargetFPS(FPS)
    
    textures:= make(map[string][dynamic]rl.Texture)
    textures["idle"] = load_textures_from_directory("assets/player/idle")
    textures["run"] = load_textures_from_directory("assets/player/run")
    textures["attack"] = load_textures_from_directory("assets/player/attack")
    textures["fall"] = load_textures_from_directory("assets/player/fall")
    textures["jump"] = load_textures_from_directory("assets/player/jump")
    defer unload_textures(&textures)

    for key, value in textures {
        fmt.printfln("key: %v, value: %v", key, value)
    }

    // player
    anim_start := ANIMATION_NAME.IDLE
    anim_start_ctring := get_animation_string(anim_start)
    player := Player{
        position = {f32(WIDTH/2 - textures[anim_start_ctring][0].width/2), f32(HEIGHT/2 - textures[anim_start_ctring][0].height/2)}, 
        speed = 20, 
        state = .IDLE,
        previous_state = .IDLE,
        animation_frame_length = 0.1,
        animation_current_frame = 0,
        run_frame_timer = 0.0,
    }

    for !rl.WindowShouldClose() {
        // update
        switch_state(&player)
        current_animation_texture := update_animation(&player, &textures)

        // render
        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND)
        draw_player(player, current_animation_texture)
        draw_debug(player)
        rl.EndDrawing()
    }
    rl.CloseWindow()
}