package main

import "core:fmt"
import rl "vendor:raylib"

gravity: f32 = 500 // pixels per second squared

ANIMATION_NAME :: enum {
    ATTACK,
    IDLE,
    JUMP, 
    RUN, 
}

Player :: struct {
    position: [2]f32,
    velocity: [2]f32,
    width: f32,
    height: f32,
    offset_x: i32, // offset from texture center to the left for collider rect
    offset_y: i32, // offset from texture center to the left for collider rect,
    collider_width: f32,
    collider_height: f32,
    grounded: bool,
    was_grounded: bool,
    state: ANIMATION_NAME,
    previous_state: ANIMATION_NAME,
    animation_frame_length: f32, // duration of a single animation frame
    animation_current_frame: i32, // index of the frame/png in the current animation
    run_frame_timer: f32 // how long the current frame has been displayed, in seconds
}

get_player_rect :: proc (player: Player) -> rl.Rectangle {
    // return a Rectangle based on player current position
    return rl.Rectangle {
            player.position.x + 38,
            player.position.y + player.height - 58,
            player.collider_width,
            player.collider_height,
        }
}

draw_player :: proc(player: Player, texture: rl.Texture) {
    // draw the player from an animation texture
    rl.DrawTextureEx(texture, player.position, 0.0, 1.0, rl.RAYWHITE)
}

get_animation_string:: proc(anim: ANIMATION_NAME) -> string {
    // convert player animation state to string
    switch anim {
        case .ATTACK:     return "attack"
        case .IDLE:       return "idle"
        case .JUMP:       return "jump"
        case .RUN:        return "run"
        case:             return  "idle"
    }
}

switch_state:: proc(player: ^Player) {
    // switch player state based on KB input
    if rl.IsKeyDown(.A) {
        player.state = .ATTACK
    }
    else if rl.IsKeyDown(.SPACE) {
        player.state = .JUMP
    }
    else if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.RIGHT) {
        player.state = .RUN
    }
    else {
        player.state = .IDLE
    }
}

update_animation :: proc(
    /*
    update player animation based on delta time and state
    - for a given animation:
        - accumulate the time of the current frame
        - if time > animation_frame_length (set in player instantiation), move the next frame
        - reset player.run_frame_timer
    - if current state different from previous state:
        - reset animation frame to the first one
        - reset run_frame_timer
    */
    player: ^Player,
    textures: ^map[string][dynamic]rl.Texture,
) -> rl.Texture {
    if player.state != player.previous_state {
        player.animation_current_frame = 0
        player.run_frame_timer = 0
        player.previous_state = player.state
    }

    animation_name := get_animation_string(player.state)
    frames := textures[animation_name]
    frame_count := len(frames)

    if frame_count == 0 {
        return rl.Texture{}
    }

    // Keep the index valid, even if it was changed elsewhere.
    if player.animation_current_frame < 0 ||
       player.animation_current_frame >= i32(frame_count) {
        player.animation_current_frame = 0
    }

    player.run_frame_timer += rl.GetFrameTime()

    if frame_count > 1 && player.animation_frame_length > 0 &&
       player.run_frame_timer >= player.animation_frame_length {
        player.run_frame_timer -= player.animation_frame_length
        player.animation_current_frame =
            (player.animation_current_frame + 1) % i32(frame_count)
    }

    return frames[player.animation_current_frame]
}

update_player :: proc(player: ^Player, platforms: [dynamic]Platform) {

    dt := rl.GetFrameTime()
    // Grounded must be recalculated every frame.
    player.was_grounded = player.grounded
    player.grounded = false

    if rl.IsKeyDown(.LEFT) {
        player.velocity.x = -200
    } else if rl.IsKeyDown(.RIGHT) {
        player.velocity.x = 200
    } else {
        player.velocity.x = 0
    }

    // jump
    if player.was_grounded && rl.IsKeyPressed(.SPACE){
        player.velocity.y = -300
    }

    // apply gravity
    player.velocity.y += gravity * dt

    // Move horizontally first.
    player.position.x += player.velocity.x * dt
    resolve_collision(player, platforms, .X)

    // Move vertically.
    player.position.y += player.velocity.y * dt
    resolve_collision(player, platforms, .Y)
}
