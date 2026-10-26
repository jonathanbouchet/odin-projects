package main

import rl "vendor:raylib"
import "core:math"

clamp_f32 :: proc(v, min_value, max_value: f32) -> f32 {
    if v < min_value {
        return min_value
    }
    if v > max_value {
        return max_value
    }
    return v
}

length3 :: proc(v: rl.Vector3) -> f32 {
    return math.sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2])
}

normalize3 :: proc(v: rl.Vector3) -> rl.Vector3 {
    length := length3(v)
    if length <= 0.0001 {
        return { 0, 0, 0 }
    }
    return v / length
}

cross3 :: proc(a, b: rl.Vector3) -> rl.Vector3 {
    return {
        a[1]*b[2] - a[2]*b[1],
        a[2]*b[0] - a[0]*b[2],
        a[0]*b[1] - a[1]*b[0],
    }
}

update_camera :: proc(camera: ^rl.Camera3D, dt: f32) {
    // Camera-to-target vector.
    offset := camera.position - camera.target
    distance := length3(offset)

    // Mouse panning.
    if rl.IsMouseButtonDown(.LEFT) {
        mouse_delta := rl.GetMouseDelta()

        forward := normalize3(camera.target - camera.position)

        // Camera right vector.
        right := normalize3(cross3(forward, camera.up))

        // Screen-up vector.
        screen_up := normalize3(cross3(right, forward))

        // Scale panning with camera distance so it feels consistent
        // when zoomed in or out.
        pan_speed := 0.01 * distance

        pan := right * (-mouse_delta[0] * pan_speed)
        pan += screen_up * (mouse_delta[1] * pan_speed)

        camera.position += pan
        camera.target += pan
    }

    // Rotate around the target using the left/right arrow keys.
    yaw_speed := f32(1.8) // radians per second

    yaw := f32(0)
    if rl.IsKeyDown(.LEFT) {
        yaw -= yaw_speed * dt
    }
    if rl.IsKeyDown(.RIGHT) {
        yaw += yaw_speed * dt
    }

    if yaw != 0 {
        c := math.cos(yaw)
        s := math.sin(yaw)

        // Rotate the camera offset around the Y axis.
        rotated_offset := rl.Vector3{
            offset[0] * c - offset[2] * s,
            offset[1],
            offset[0] * s + offset[2] * c,
        }

        camera.position = camera.target + rotated_offset
    }

    // Recalculate distance after panning/rotation.
    offset = camera.position - camera.target
    distance = length3(offset)

    // Zoom using up/down arrow keys.
    zoom_speed := f32(12.0) // world units per second
    zoom := f32(0)

    if rl.IsKeyDown(.UP) {
        zoom -= zoom_speed * dt
    }
    if rl.IsKeyDown(.DOWN) {
        zoom += zoom_speed * dt
    }

    distance = clamp_f32(distance + zoom, 2.0, 100.0)

    // Move along the camera-target direction while preserving the orbit.
    direction := normalize3(camera.position - camera.target)
    camera.position = camera.target + direction * distance
}