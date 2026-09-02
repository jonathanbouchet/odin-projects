package imgui_testing

import "core:fmt"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl" // Required for modern Odin raylib integrations
import imgui "../../external_packages/odin-imgui-main"
import rlimgui "../../external_packages/backend/rlimgui"

main :: proc(){
    fmt.println("hellope")
    // Initialize raylib
    rl.InitWindow(600, 600, "Odin + Raylib + ImGui")
    rl.SetTargetFPS(60)
    defer rl.CloseWindow()

    imgui.CreateContext(nil)
	defer imgui.DestroyContext(nil)

    // Initialize ImGui Backend
    rlimgui.init()
    defer rlimgui.shutdown()

    counter:= 0

    for !rl.WindowShouldClose() {
        // --- Update & Event Handling ---
        // Let the backend process mouse, keyboard, and window scaling changes
        rlimgui.process_events()
        rlimgui.new_frame() 
        imgui.NewFrame()

        // // --- Define ImGui UI Layout ---
        // imgui.Begin("Debug Control Panel")

        // imgui.Text("Hello from Odin!")
        // if imgui.Button("Increment Counter") {
        //     counter += 1
        // }
        // imgui.Text("Count: %d", counter)

        // imgui.End()

        rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

        imgui.ShowDemoWindow(nil) // use this for default demo

        imgui.Render()
		rlimgui.render_draw_data(imgui.GetDrawData())

        rl.EndDrawing()
    }
}
