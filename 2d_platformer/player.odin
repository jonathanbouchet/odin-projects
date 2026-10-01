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
    grounded: bool
}

update_player :: proc (player: ^Player, collision_layer: ^Texture_Layer) {
    x: f32
    y: f32
    i: f32
    j: f32
    tile_value: i32

    dt := rl.GetFrameTime()

    if rl.IsKeyDown(.LEFT) {
        player.velocity.x = -200
    } else if rl.IsKeyDown(.RIGHT) {
        player.velocity.x = 200
    } else {
        player.velocity.x = 0
    }

    // apply gravity
    player.velocity.y += gravity * dt

    // jump
    if player.grounded && rl.IsKeyPressed(.SPACE){
        player.velocity.y = -300
    }

    player.position += player.velocity * dt

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
            
            if rl.CheckCollisionRecs(player_rect, dest_rect) && player.velocity.y !=0 { //} && player.velocity.y > 0{
                fmt.printfln("player vx: %v, vy:%v", player.velocity.x, player.velocity.y)
                if player.velocity.y < 0 {
                    player.position.y = dest_rect.y + dest_rect.height
                    player.velocity.y = 0
                    player.grounded = false
                } else if player.velocity.y > 0 {
                        player.position.y = dest_rect.y - player_rect.height
                        player.velocity.y = 0 // if not, player_vel.y still accumulates and it might go through the tile
                        player.grounded = true
                }
            }
        }
    }
}

draw_player :: proc (player: Player) {
    rl.DrawRectangleV(player.position, rl.Vector2{player.width, player.height}, player.color)
}