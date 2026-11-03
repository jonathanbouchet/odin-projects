package main

import "core:math"
import "core:fmt"
import rl "vendor:raylib"

clamp_f32 :: proc(v, min_value, max_value: f32) -> f32 {
    if v < min_value {
        return min_value
    }
    if v > max_value {
        return max_value
    }
    return v
}


bool_to_32 :: proc(value: bool) -> f32 {
    if value {
        return 1.0
    } else{
        return -1.0
    }
}

f32_to_bool :: proc(value: f32) -> bool {
    if value == 1.0{
        return true
    } else{
        return false
    }
}

Player :: struct {
    position: rl.Vector3,
    velocity: rl.Vector3,
    speed: f32,
    eyes: f32,
    yaw: f32,
    pitch: f32,
    sensitivity: f32,
    is_colliding: bool,
}

player_bounding_box :: proc(player: Player) -> rl.BoundingBox {
    // return a rough bounding box around the player current position 
    player_next_pos := player.position + rl.Vector3{1, 0, 1}
    return rl.BoundingBox{player.position, player_next_pos}
}

player_bounding_box_adjusted :: proc(player: Player) -> rl.BoundingBox {
    half_width: f32 = 0.25
    height: f32 = 1.0

    return rl.BoundingBox{
        min = rl.Vector3{
            player.position.x - half_width,
            player.position.y,
            player.position.z - half_width,
        },
        max = rl.Vector3{
            player.position.x + half_width,
            player.position.y + height,
            player.position.z + half_width,
        },
    }
}

update_player :: proc(
    player: ^Player,
    camera: ^rl.Camera3D,
    walls: [dynamic]rl.BoundingBox,
) {
    dt := rl.GetFrameTime()
    move_speed := player.speed * dt

    mouse_delta := rl.GetMouseDelta()
    player.yaw -= mouse_delta.x * player.sensitivity
    player.pitch -= mouse_delta.y * player.sensitivity

    max_pitch: f32 = math.PI / 2.0 - 0.01
    player.pitch = clamp_f32(player.pitch, -max_pitch, max_pitch)

    forward := rl.Vector3{
        math.sin(player.yaw),
        0,
        math.cos(player.yaw),
    }
    right := rl.Vector3{
        math.cos(player.yaw),
        0,
        -math.sin(player.yaw),
    }

    // Combine input directions into one world-space movement vector.
    move := rl.Vector3{}
    if rl.IsKeyDown(.UP)    { move += forward }
    if rl.IsKeyDown(.DOWN)  { move -= forward }
    if rl.IsKeyDown(.LEFT)  { move += right }
    if rl.IsKeyDown(.RIGHT) { move -= right }

    // Prevent diagonal movement from being faster.
    if rl.Vector3Length(move) > 0 {
        move = rl.Vector3Normalize(move) * move_speed
    }

    player.is_colliding = false

    // Move and resolve X first.
    player.position.x += move.x
    player_bb := player_bounding_box_adjusted(player^)
    for wall in walls {
        if rl.CheckCollisionBoxes(wall, player_bb) {
            player.position.x -= move.x
            player.is_colliding = true
            break
        }
    }

    // Then move and resolve Z, using the possibly updated X position.
    player.position.z += move.z
    player_bb = player_bounding_box_adjusted(player^)
    for wall in walls {
        if rl.CheckCollisionBoxes(wall, player_bb) {
            player.position.z -= move.z
            player.is_colliding = true
            break
        }
    }

    camera.position = rl.Vector3{
        player.position.x,
        player.position.y + player.eyes,
        player.position.z,
    }

    direction := rl.Vector3{
        math.cos(player.pitch) * math.sin(player.yaw),
        math.sin(player.pitch),
        math.cos(player.pitch) * math.cos(player.yaw),
    }
    camera.target = camera.position + direction
}
