#+feature dynamic-literals
package main

import "core:mem"
import "core:fmt"
import "core:math"
import "core:strings"
import rl "vendor:raylib"

WIDTH :: 1280
HEIGHT :: 640
FPS :: 60
BACKGROUND :: rl.Color{0, 0, 28, 255}
TILE_WIDTH :: 64
// BACKGROUND :: rl.Color{15, 15, 15, 255}
// BACKGROUND :: rl.Color{ 150, 190, 220, 255 }
GREEN :: rl.Color{57, 255, 20, 255}
NUM_TILE_X :: 20
NUM_TILE_Y :: 10

draw_debug :: proc(player: Player) {
    /*
    various "debug" utils:
    - draw the FPS number
    - draw lines, h and v, representing the mid-screen
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
    player_pos_text := fmt.ctprintf("X: %v Y: %v", math.round(player.position.x), math.round(player.position.y))
    rl.DrawText(player_pos_text, 0, 40, 20, rl.DARKGREEN)
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

    // read input data
    map_data := read_input_data("assets/tilesets/level_20x10.tmj", Map_Data)
    // delete the dynamically alocated fields
    defer delete(map_data.layers)
    fmt.println(typeid_of(type_of(map_data))) 
    fmt.printfln("# of layers: %v", len(map_data.layers))

    platform_layer: ^Texture_Layer = nil
    collision_layer: ^Texture_Layer = nil

    platform_layer = extract_layer_data(map_data, 1)
    collision_layer = extract_layer_data(map_data, 3)

    if platform_layer != nil {
        fmt.println("Found layer:", platform_layer.name)
    }

    if collision_layer != nil {
        fmt.println("Found layer:", collision_layer.name)
    }

    fmt.printfln("platform layer: %v", platform_layer)
    fmt.println(typeid_of(type_of(platform_layer))) 

    fmt.printfln("collision layer: %v", collision_layer)
    fmt.println(typeid_of(type_of(collision_layer)))
    
    platforms: [dynamic]Platform
    defer delete(platforms)

    for collision_block in collision_layer.objects {
        fmt.printfln("collision block: %v", collision_block)
        append(&platforms, Platform {
            x = i32(collision_block.x), 
            y = i32(collision_block.y), 
            width = i32(collision_block.width), 
            height = i32(collision_block.height), 
            color = GREEN
        })
    }

    texture := rl.LoadTexture("assets/tilesets/outside.png")
    defer rl.UnloadTexture(texture)
    
    textures:= make(map[string][dynamic]rl.Texture)
    textures["idle"] = load_textures_from_directory("assets/player/idle")
    textures["run"] = load_textures_from_directory("assets/player/run")
    textures["attack"] = load_textures_from_directory("assets/player/attack")
    textures["fall"] = load_textures_from_directory("assets/player/fall")
    textures["jump"] = load_textures_from_directory("assets/player/jump")
    defer unload_textures(&textures)

    // player
    anim_start := ANIMATION_NAME.IDLE
    anim_start_ctring := get_animation_string(anim_start)
    player := Player{
        position = {
            f32(WIDTH/2 - textures[anim_start_ctring][0].width/2), 
            f32(200)
        },
        velocity = rl.Vector2{0, 0},
        width = f32(textures[anim_start_ctring][0].width),
        height = f32(textures[anim_start_ctring][0].height),
        offset_x = 0,
        offset_y = 0,
        collider_width = 32,
        collider_height = 40,
        grounded = false,
        was_grounded = false,
        state = .IDLE,
        previous_state = .IDLE,
        animation_frame_length = 0.1,
        animation_current_frame = 0,
        run_frame_timer = 0.0,
    }

    for !rl.WindowShouldClose() {
        // update
        switch_state(&player)
        update_player(&player, platforms)
        current_animation_texture := update_animation(&player, &textures)

        // render
        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND)
        draw_layer(texture, platform_layer, false)
        draw_player(player, current_animation_texture)
        draw_debug(player)
        draw_platforms_lines(platforms)
        rl.EndDrawing()
    }
    rl.CloseWindow()
}