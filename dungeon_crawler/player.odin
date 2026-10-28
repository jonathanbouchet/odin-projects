package main

import "core:math"
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
    speed: f32,
    eyes: f32,
    yaw: f32,
    pitch: f32,
    sensitivity: f32,
}

update_player :: proc (player: ^Player, camera: ^rl.Camera3D) {
    // mouse input
    mouse_delta := rl.GetMouseDelta()
    player.yaw -= mouse_delta.x * player.sensitivity
    player.pitch -= mouse_delta.y * player.sensitivity

    // clamp pitch to avoid flipping over the top/bottom
    max_pitch:f32 = math.PI / 2.0 - 0.01
    player.pitch = clamp_f32(player.pitch, -max_pitch, max_pitch)
    // freeze the vertical camera movement
    // player.pitch = 0

    // handle movement input
    move_speed := player.speed * rl.GetFrameTime()

    forward := rl.Vector3{
        math.sin(player.yaw),
        0.0,
        math.cos(player.yaw),
    }
    right := rl.Vector3{
        math.cos(player.yaw),
        0.0,
        -math.sin(player.yaw),
    }

    if rl.IsKeyDown(.UP) {
        player.position.x += forward.x * move_speed
        player.position.z += forward.z * move_speed
    }
    if rl.IsKeyDown(.DOWN) {
        player.position.x -= forward.x * move_speed
        player.position.z -= forward.z * move_speed
    }
    if rl.IsKeyDown(.LEFT) {
        player.position.x += right.x * move_speed
        player.position.z += right.z * move_speed
    }
    if rl.IsKeyDown(.RIGHT) {
        player.position.x -= right.x * move_speed
        player.position.z -= right.z * move_speed
    }

    // attach camera to the player's head/eyes
        camera.position = rl.Vector3{
            player.position.x,
            player.position.y + player.eyes,
            player.position.z,
        }

    // calculate look direction from yaw and pitch
    direction := rl.Vector3{
        math.cos(player.pitch) * math.sin(player.yaw),
        math.sin(player.pitch),
        math.cos(player.pitch) * math.cos(player.yaw),
    }

    camera.target = camera.position + direction
}