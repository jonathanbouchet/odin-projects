#+feature dynamic-literals
package main

import "core:mem"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

WIDTH :: 600
HEIGHT :: 600
FPS :: 60
// BACKGROUND :: rl.Color{0, 0, 28, 255}
TILE_WIDTH :: 64
BACKGROUND :: rl.Color{15, 15, 15, 255}
// BACKGROUND :: rl.Color{ 150, 190, 220, 255 }
GREEN :: rl.Color{57, 255, 20, 255}

draw_platform :: proc(texture: rl.Texture, tile_id: i32) {
    // draw a tile from a tileset
    i: i32 = 5
    j: i32 = 5
    source_rect := rl.Rectangle{f32(1 * TILE_WIDTH), f32(0 * TILE_WIDTH), TILE_WIDTH, TILE_WIDTH }
    dest_rect := rl.Rectangle{f32(i*TILE_WIDTH), f32(j*TILE_WIDTH), TILE_WIDTH, TILE_WIDTH} 
    rl.DrawTexturePro(texture, source_rect, dest_rect, rl.Vector2{0, 0}, 0.0,  rl.RAYWHITE)
}

draw_debug :: proc(player: Player) {
    /*
    various "debug" utils:
    - draw the FPS number
    - draw  lines, h and v, representing the mid-screen
    - draw player state
    */
    rl.DrawFPS(0, 0)
    rl.DrawLineV(rl.Vector2{0, HEIGHT/2}, {WIDTH, HEIGHT/2}, rl.RED)
    rl.DrawLineV(rl.Vector2{WIDTH/2, 0}, {WIDTH/2, HEIGHT}, rl.RED)
    player_state_string, ok := fmt.enum_value_to_string(player.state)
    if ok {
        player_state_cstring := strings.clone_to_cstring(player_state_string)
        defer delete(player_state_cstring)
        rl.DrawText(player_state_cstring, 0, 20, 20, rl.DARKGREEN)
    }
    player_rect := get_player_rect(player)
    rl.DrawRectangleLinesEx(player_rect, 1.0, rl.YELLOW)
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
        position = {
            f32(WIDTH/2 - textures[anim_start_ctring][0].width/2), 
            f32(200)
        },
        // position = {
        //     f32(WIDTH/2 - textures[anim_start_ctring][0].width/2), 
        //     f32(HEIGHT/2 - textures[anim_start_ctring][0].height/2)
        // }, 
        velocity = rl.Vector2{0, 0},
        width = f32(textures[anim_start_ctring][0].width),
        height = f32(textures[anim_start_ctring][0].height),
        state = .IDLE,
        previous_state = .IDLE,
        animation_frame_length = 0.1,
        animation_current_frame = 0,
        run_frame_timer = 0.0,
    }

    // a platform defined from a tileset
    // outside := rl.LoadTexture("assets/tilesets/outside.png")
    // defer rl.UnloadTexture(outside)
    // testing
    // tile_id: i32 = 0

    // platforms defined from Raylib basic shape 
    ground := Platform{
        x = 0, y = 400, width = rl.GetScreenWidth(), height = 50, color = GREEN
    }

    p1 := Platform{
        x = 100, y = 200, width = 100, height = 20, color = GREEN
    }

    platforms := [dynamic]Platform{ground, p1} 
    defer delete(platforms)

    for !rl.WindowShouldClose() {
        // update
        switch_state(&player)
        update_player(&player, platforms)
        current_animation_texture := update_animation(&player, &textures)

        // render
        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND)
        draw_player(player, current_animation_texture)
        draw_debug(player)
        draw_platforms_lines(platforms)
        // draw_platform(outside, tile_id)
        rl.EndDrawing()
    }
    rl.CloseWindow()
}