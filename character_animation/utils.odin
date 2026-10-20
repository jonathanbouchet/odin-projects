package main

import "core:fmt"
import rl "vendor:raylib"

Axis :: enum {
    X,
    Y,
}

resolve_collision :: proc (player: ^Player, platforms: [dynamic]Platform, axis: Axis) {
    /*
    - method to check lateral and vertical collisions between the player and the platforms
    */

    for platform in platforms {
        platform_rect := get_platform_rect(platform)
        player_rect := get_player_rect(player^)

        // quick abort if there's no collisions
        if !rl.CheckCollisionRecs(player_rect, platform_rect) {
            continue
        }

        switch axis {
            case .X:
                fmt.printfln("collision X")
                if player.velocity.x > 0 {
                    player.position.x += platform_rect.x - (player_rect.x + player_rect.width)
                } else if player.velocity.x < 0 {
                    player.position.x += (platform_rect.x + platform_rect.width) - player_rect.x
                }
            player.velocity.x = 0
            case .Y:
                if player.velocity.y < 0 {
                    player.position.y += (platform_rect.y + platform_rect.height) - player_rect.y
                } else if player.velocity.y > 0 {
                    player.position.y += platform_rect.y - (player_rect.y + player_rect.height)
                    player.grounded = true
                    // break
                }
            player.velocity.y = 0
        }
    }
}