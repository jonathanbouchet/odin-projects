package threeDgrid

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

import imgui "../../../ODIN_REPO/external_packages/odin-imgui-main"
import rlimgui "../../../ODIN_REPO/external_packages/backend/rlimgui"

imgui_display :: proc() {
    style := imgui.GetStyle()
    style.FontScaleMain = 1.0
    
    // Let the backend process mouse, keyboard, and window scaling changes
    rlimgui.process_events()
    rlimgui.new_frame() 
    imgui.NewFrame()
    fps := 1.0 / rl.GetFrameTime()
    fps_text := fmt.tprintf("FPS: %.1f (%.2f ms)", fps, rl.GetFrameTime() * 1000.0)
    fps_cstring := strings.clone_to_cstring(fps_text, context.temp_allocator)

    window_size_text := fmt.tprintf("W: %d H: %d", rl.GetScreenWidth(), rl.GetScreenHeight())
    window_size_text_cstring := strings.clone_to_cstring(window_size_text, context.temp_allocator)

    // --- Define ImGui UI Layout ---
    imgui.Begin("Debug")
    imgui.SeparatorText("Window")
    imgui.TextUnformatted(fps_cstring)
    imgui.TextUnformatted(window_size_text_cstring)

    imgui.End()
}