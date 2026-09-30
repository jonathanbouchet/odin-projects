package main

import rl "vendor:raylib"

gravity: f32 = 100.0 // pixels per second squared

Player :: struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    rotation: f32,
    width: f32,
    height: f32,
    color: rl.Color
}

update_player :: proc (player: ^Player) {
    dt := rl.GetFrameTime()
    player.velocity.y += gravity * dt
    player.position += player.velocity * dt
}

draw_player :: proc (player: Player) {
    rl.DrawRectangleV(player.position, rl.Vector2{player.width, player.height}, player.color)
}