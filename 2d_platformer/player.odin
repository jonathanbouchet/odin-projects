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

update_player :: proc (player: ^Player, collision_layer: ^Texture_Layer) {
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

    for tile_id in 0..<len(collision_layer.data) {
        if collision_layer.data[tile_id] <= 0 {
            continue
        }

        tile_x := f32(tile_id % NUM_TILE_X)
        tile_y := f32(tile_id / NUM_TILE_X)

        tile_rect := rl.Rectangle{
            tile_x * TILE_WIDTH,
            tile_y * TILE_WIDTH,
            TILE_WIDTH,
            TILE_WIDTH,
        }

        player_rect := rl.Rectangle{
            player.position.x,
            player.position.y,
            player.width,
            player.height,
        }

        if rl.CheckCollisionRecs(player_rect, tile_rect) {
            if player.velocity.x > 0 {
                // Moving right: place player's right edge at tile's left edge.
                player.position.x = tile_rect.x - player.width
            } else if player.velocity.x < 0 {
                // Moving left: place player's left edge at tile's right edge.
                player.position.x = tile_rect.x + tile_rect.width
            }

            player.velocity.x = 0
        }
    }

    // Move vertically.
    player.position.y += player.velocity.y * dt

    // check collisions
    // player_rect := rl.Rectangle{player.position.x, player.position.y, player.width, player.height}
    for tile_id in 0..<len(collision_layer.data) {
        if collision_layer.data[tile_id] > 0 {
            tile_value = collision_layer.data[tile_id]
            y = math.floor_f32(f32(tile_value) / NUM_TILE_X)
            x = f32(tile_value - 1) - f32(y*NUM_TILE_X)

            j = math.floor_f32(f32(tile_id) / NUM_TILE_X)
            i = f32(tile_id % NUM_TILE_X)

            dest_rect := rl.Rectangle{
                    f32(i*TILE_WIDTH), 
                    f32(j*TILE_WIDTH), 
                    TILE_WIDTH, 
                    TILE_WIDTH
                }
            // a more accurate player position (?)
            player_rect := rl.Rectangle{player.position.x, player.position.y, player.width, player.height}
            
            if rl.CheckCollisionRecs(player_rect, dest_rect) {
                if player.velocity.y < 0 {
                        player.position.y = dest_rect.y + dest_rect.height
                        player.velocity.y = 0
                } else if player.velocity.y > 0 {
                        player.position.y = dest_rect.y - player_rect.height
                        player.velocity.y = 0 // if not, player_vel.y still accumulates and it might go through the tile
                        player.grounded = true
                }
                player.velocity.y = 0
            }
        }
    }
}

draw_player :: proc (player: Player) {
    rl.DrawRectangleV(player.position, rl.Vector2{player.width, player.height}, player.color)
}