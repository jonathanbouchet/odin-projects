package main

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
    HP: i32,
    coins_collected: i32,
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