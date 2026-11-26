package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

import imgui "../../../ODIN_REPO/external_packages/odin-imgui-main"
import rlimgui "../../../ODIN_REPO/external_packages/backend/rlimgui"

imgui_display :: proc(game: ^Game) {
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

    // --- Define ImGui UI Layout ---
    imgui.Begin("Debug")
    imgui.SeparatorText("Window")
    imgui.TextUnformatted(fps_cstring)
    imgui.TextUnformatted(window_size_text_cstring)

    imgui.SeparatorText("light position")
    imgui.SliderFloat3("##LightPos", &game.light_direction, 0.0, 1.0, "%.2f")
    imgui.SameLine()
    if imgui.Button("reset##LD"){
        game.light_direction[0] = 0.0
        game.light_direction[1] = 0.0
        game.light_direction[2] = 0.0
    }

    imgui.SeparatorText("light color")
    imgui.SliderFloat3("##LightColor", &game.light_color, 0.0, 1.0, "%.2f")
    imgui.SameLine()
    if imgui.Button("reset##LC"){
        game.light_color[0] = 1.0
        game.light_color[1] = 1.0
        game.light_color[2] = 1.0
    }

    imgui.SeparatorText("ambient color")
    imgui.SliderFloat3("##Ambient", &game.ambient_color, 0.0, 1.0, "%.2f")
    imgui.SameLine()
    if imgui.Button("reset##AC"){
        game.ambient_color[0] = 1.0
        game.ambient_color[1] = 1.0
        game.ambient_color[2] = 1.0
    }

    imgui.End()
}