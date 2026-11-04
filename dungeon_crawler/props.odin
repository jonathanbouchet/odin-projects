package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

Animation_To_Model :: struct {
    frames: [dynamic]rl.Model,
    position: rl.Vector3,
    animation_frame_length: f32,  // duration of a single animation frame
    animation_current_frame: i32, // index of the frame/png in the current animation
    run_frame_timer: f32,         // how long the current frame has been displayed, in seconds
}

make_model_from_animations :: proc(path: string, start_anim: i32, max_anim: i32, mesh_cube: [3]f32) -> [dynamic]rl.Model{
    /*
    - make models from animations png files
    - loop over each png and generate 1) a mesh cube 2) then a model from the mesh cube
    - take mesh cube parameters to take into account flat textures, like flames
    */
    fmt.printfln("path: %v, start_anim:%v, max_anim:%v, mesh_cube:%v", path, start_anim, max_anim, mesh_cube)
    tmp: [dynamic]rl.Model
    for i in start_anim..<max_anim {
        full_path := fmt.tprintf("%s%d.png", path, i)
        fmt.printfln("i%v, path:%v", i, full_path)
        path_cstring := strings.clone_to_cstring(full_path)
        defer delete(path_cstring)
        t := rl.LoadTexture(path_cstring)
        fmt.printfln("width: %v, height:%v", t.width, t.height)
        m := rl.LoadModelFromMesh(rl.GenMeshCube(mesh_cube[0], mesh_cube[1], mesh_cube[2]))
        m.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = t
        // tmp[i] = m
        append(&tmp, m)
    }
    return tmp
}

draw_animation_model :: proc(fl: ^Animation_To_Model) {
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