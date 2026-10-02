package main

import "core:math"
import rl "vendor:raylib"

Axis :: enum {
    X,
    Y,
}

resolve_collision :: proc (player: ^Player, collision_layer: ^Texture_Layer, axis: Axis) {
    /*
    - method to check lateral and vertical collisions between the player and the tiles form the collision layer
    - only the neightboring tiles are checked, no need to check all of them
    - thus, the loop is not over the full collision.data but now it's a double loop over X and Y neightbors
    */
    player_rect := get_player_rect(player)
    
    min_x := max(0, i32(math.floor_f32(player_rect.x / TILE_WIDTH)))
    min_y := max(0, i32(math.floor_f32(player_rect.y / TILE_WIDTH)))

    max_x := min(
        NUM_TILE_X - 1,
        i32(math.floor_f32((player_rect.x + player_rect.width) / TILE_WIDTH)),
    )

    max_y := min(
        NUM_TILE_Y - 1,
        i32(math.floor_f32((player_rect.y + player_rect.height) / TILE_WIDTH)),
    )

    for tile_y in min_y..=max_y {
        for tile_x in min_x..=max_x {
            tile_id := tile_y * NUM_TILE_X + tile_x
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

            player_rect := get_player_rect(player)

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
    }
