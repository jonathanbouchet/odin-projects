package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

import imgui "../../../ODIN_REPO/external_packages/odin-imgui-main"
import rlimgui "../../../ODIN_REPO/external_packages/backend/rlimgui"

imgui_display :: proc(light_pos: ^[3]f32, light_color: ^[3]f32, ambient_color: ^[3]f32) {
    style := imgui.GetStyle()
    style.FontScaleMain = 1.0
    
    // Let the backend process mouse, keyboard, and window scaling changes
    rlimgui.process_events()
    rlimgui.new_frame() 
    imgui.NewFrame()
    fps:= 1.0 / rl.GetFrameTime()
    fps_text := fmt.tprintf("FPS: %.1f (%.2f ms)", fps, rl.GetFrameTime() * 1000.0)
    fps_cstring := strings.clone_to_cstring(fps_text, context.temp_allocator)

    window_size_text := fmt.tprintf("W: %d H: %d", rl.GetScreenWidth(), rl.GetScreenHeight())
    window_size_text_cstring := strings.clone_to_cstring(window_size_text, context.temp_allocator)

    // light_pos:= [3]f32{0.0, 0.0, 1.0}
    // light_color:= [3]f32{0.0, 0.0, 1.0}
    // ambient_color:= [3]f32{0.0, 0.0, 1.0}

    // imgui.SetNextWindowCollapsed(true, imgui.Cond.FirstUseEver)

    // --- Define ImGui UI Layout ---
    imgui.Begin("Debug")
    imgui.SeparatorText("Window")
    imgui.TextUnformatted(fps_cstring)
    imgui.TextUnformatted(window_size_text_cstring)

    imgui.SeparatorText("light direction")
    imgui.SliderFloat3("##LightDir", light_pos, 0.0, 1.0, "%.2f")
    imgui.SameLine()
    if imgui.Button("reset##LD"){
        light_pos[0] = -1.0
        light_pos[1] = -1.0
        light_pos[2] = -1.0
    }

    imgui.SeparatorText("light color")
    imgui.SliderFloat3("##LightColor", light_color, 0.0, 1.0, "%.2f")
    imgui.SameLine()
    if imgui.Button("reset##LC"){
        light_color[0] = 0.7
        light_color[1] = 0.7
        light_color[2] = 0.7
    }

    imgui.SeparatorText("ambient color")
    imgui.SliderFloat3("##Ambient", ambient_color, 0.0, 1.0, "%.2f")
    imgui.SameLine()
    if imgui.Button("reset##AC"){
        ambient_color[0] = 0.25
        ambient_color[1] = 0.25
        ambient_color[2] = 0.25
    }

    // fmt.printfln("light direction : %v, light color: %v, ambient color: %v", light_pos, light_color, ambient_color)

    imgui.End()
}