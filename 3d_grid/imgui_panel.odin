package threeDgrid

import rl "vendor:raylib"

import imgui "../../../ODIN_REPO/external_packages/odin-imgui-main"
import rlimgui "../../../ODIN_REPO/external_packages/backend/rlimgui"

imgui_display :: proc(mouse_pos: rl.Vector2, gridX: i32, gridZ: i32, light_pos: ^[3]f32, light_color: ^[3]f32, ambient_color: ^[3]f32) {
    style := imgui.GetStyle()
    style.FontScaleMain = 1.0
    m := [2]i32{gridX, gridZ}
    p := [2]f32{mouse_pos.x, mouse_pos.y}
    
    // Let the backend process mouse, keyboard, and window scaling changes
    rlimgui.process_events()
    rlimgui.new_frame() 
    imgui.NewFrame()
    fps := 1.0 / rl.GetFrameTime()
    fr := rl.GetFrameTime() * 1000.0
    w := [2]i32{rl.GetScreenWidth(), rl.GetScreenHeight()}
   
    // --- Define ImGui UI Layout ---
    imgui.Begin("Debug")
    imgui.SeparatorText("Window")

    imgui.Text("fps")
    imgui.SameLine()
    imgui.SetNextItemWidth(50.0)
    imgui.InputFloat("##fps", &fps)
    imgui.SameLine()
    imgui.SetNextItemWidth(30.0)
    imgui.Text("frame rate")
    imgui.SameLine()
    imgui.SetNextItemWidth(50.0)
    imgui.InputFloat("##frame rate", &fr)

    imgui.Text("resolution")
    // imgui.SameLine()
    // imgui.SetNextItemWidth(50.0)
    // imgui.InputInt("##width", &width)
    // imgui.SameLine()
    // imgui.SetNextItemWidth(30.0)
    // imgui.Text("height")
    // imgui.SameLine()
    // imgui.SetNextItemWidth(50.0)
    // imgui.InputInt("##height", &height)
    imgui.InputInt2("##screensize",&w)

    imgui.SeparatorText("mouse position")
    imgui.InputFloat2("##mousepos", &p)
    imgui.SeparatorText("grid")
    imgui.InputInt2("##grid", &m)

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

    imgui.End()
}