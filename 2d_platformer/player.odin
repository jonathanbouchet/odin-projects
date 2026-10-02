package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

gravity: f32 = 400.0 // pixels per second squared

Player :: struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    rotation: f32,
    width: f32,
    height: f32,
    color: rl.Color,
    grounded: bool,
    was_grounded: bool
}

get_player_rect :: proc (player: ^Player) -> rl.Rectangle {
    // return a Rectangle based on player current position
    return rl.Rectangle {
            player.position.x,
            player.position.y,
            player.width,
            player.height,
        }
}

update_player :: proc (player: ^Player, collision_layer: ^Texture_Layer) {
    /*
    - update the position of the player
    - used Euler integration :
        velocity += acceleration * dt
        position += velocity * dt
    - first got input from KB for left/right or jump
    - then gravity is applied
    - position is then updated
    - finally collisions are checked
    */
    x: f32
    y: f32
    i: f32
    j: f32
    tile_value: i32

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
        player.velocity.y = -250
    }

    // apply gravity
    player.velocity.y += gravity * dt

    // Move horizontally first.
    player.position.x += player.velocity.x * dt
    resolve_collision(player, collision_layer, .X)

    // Move vertically.
    player.position.y += player.velocity.y * dt
    resolve_collision(player, collision_layer, .Y)
    }

draw_player :: proc (player: Player) {
    rl.DrawRectangleV(player.position, rl.Vector2{player.width, player.height}, player.color)
}