package main

import rl "vendor:raylib"

Axis :: enum {
    X,
    Y,
}

resolve_collision :: proc (player: ^Player, collision_layer: ^Texture_Layer, axis: Axis) {
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

        // quick abort if there's no collisions
        if !rl.CheckCollisionRecs(player_rect, tile_rect) {
            continue
        }

        switch axis {
            case .X:
                if player.velocity.x > 0 {
                    // Moving right: place player's right edge at tile's left edge.
                    player.position.x = tile_rect.x - player.width
                } else if player.velocity.x < 0 {
                    // Moving left: place player's left edge at tile's right edge.
                    player.position.x = tile_rect.x + tile_rect.width
                }
                player.velocity.x = 0
            case .Y:
                if player.velocity.y < 0 {
                        player.position.y = tile_rect.y + tile_rect.height
                        player.velocity.y = 0
                } else if player.velocity.y > 0 {
                        player.position.y = tile_rect.y - player_rect.height
                        player.velocity.y = 0 // if not, player_vel.y still accumulates and it might go through the tile
                        player.grounded = true
                }
                player.velocity.y = 0
            }
        }
    }
