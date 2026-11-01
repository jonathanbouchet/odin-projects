package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

Flame_Animation :: struct {
    frames: [4]rl.Model,
    position: rl.Vector3,
    animation_frame_length: f32,  // duration of a single animation frame
    animation_current_frame: i32, // index of the frame/png in the current animation
    run_frame_timer: f32,         // how long the current frame has been displayed, in seconds
}

load_flames :: proc() -> [4]rl.Model {
    fl: [4]rl.Model
    for i in 0..<4 {
        path := fmt.tprintf("%s%d.png", "assets/textures/flame/frame_00", i)
        fmt.printfln("i%v, path:%v", i, path)
        path_cstring := strings.clone_to_cstring(path)
        defer delete(path_cstring)
        t := rl.LoadTexture(path_cstring)
        fmt.printfln("width: %v, height:%v", t.width, t.height)
        // defer rl.UnloadTexture(t)
        m := rl.LoadModelFromMesh(rl.GenMeshCube(1.0, 1.0, 0.0001))
        m.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = t
        fl[i] = m
    }
    return fl
}

draw_flames :: proc(fl: ^Flame_Animation) {
    frame_count := len(fl.frames)
    fl.run_frame_timer += rl.GetFrameTime()

    if frame_count == 0 {
        return
    }

    if frame_count > 1 && fl.animation_frame_length > 0 &&
       fl.run_frame_timer >= fl.animation_frame_length {
        fl.run_frame_timer -= fl.animation_frame_length
        fl.animation_current_frame =
            (fl.animation_current_frame + 1) % i32(frame_count)
    }

    rl.DrawModelEx(
        fl.frames[fl.animation_current_frame], 
        fl.position, 
        rl.Vector3{0, 0, 1}, 
        180.0, 
        1.0, 
        rl.RAYWHITE,
    )
}