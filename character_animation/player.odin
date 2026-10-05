package main

import rl "vendor:raylib"

ANIMATION_NAME :: enum {
    AIR_ATTACK,
    ATTACK,
    FALL,
    HIT,
    IDLE,
    JUMP, 
    RUN, 
    WALL,
}

Player :: struct {
    position: [2]f32,
    speed: i32,
    state: ANIMATION_NAME,
}

draw_player :: proc(player: Player, texture: rl.Texture) {
    rl.DrawTextureEx(texture, player.position, 0.0, 1.0, rl.RAYWHITE)
}