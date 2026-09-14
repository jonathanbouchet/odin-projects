package main

import rl "vendor:raylib"
import imgui "../../../ODIN_REPO/external_packages/odin-imgui-main"
import rlimgui "../../../ODIN_REPO/external_packages/backend/rlimgui"

SCREEN_WIDTH :: 600
SCREEN_HEIGHT :: 600
TARGET_FPS :: 60

update_shader_values :: proc(
    light_direction: ^[3]f32, 
    light_color: ^[3]f32, 
    ambient_color: ^[3]f32,
    light_direction_loc: int, 
    light_color_loc: int, 
    ambient_color_loc: int,
    shader: rl.Shader) {
    rl.SetShaderValue(
        shader,
        light_direction_loc,
        light_direction,
        rl.ShaderUniformDataType.VEC3,
    )
    rl.SetShaderValue(
        shader,
        light_color_loc,
        light_color,
        rl.ShaderUniformDataType.VEC3,
    )
    rl.SetShaderValue(
        shader,
        ambient_color_loc,
        ambient_color,
        rl.ShaderUniformDataType.VEC3,
    )
}

main :: proc() {
    // raylib window
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "3D model")
    defer rl.CloseWindow()

    // camera
    camera := rl.Camera3D{
        position   = { 0.0, 10.0, 10.0 },
        target     = { 0.0, 0.0, 0.0 },
        up         = { 0.0, 1.0, 0.0 },
        fovy       = 60.0,
        projection = .PERSPECTIVE,
    }
    rl.SetTargetFPS(TARGET_FPS)

    // model
    model := rl.LoadModel("assets/building_A.gltf") // Load model
    defer rl.UnloadModel(model)

    shader := rl.LoadShader("shaders/basic.vs", "shaders/basic.fs")
    for i in 0..<int(model.materialCount){
        model.materials[i].shader = shader
    }
    defer rl.UnloadShader(shader)
    light_direction := rl.Vector3{-1.0, -1.0, -1.0}
    light_color := rl.Vector3{0.7, 0.7, 0.7}
    ambient_color := rl.Vector3{0.25, 0.25, 0.25}

    light_direction_loc := rl.GetShaderLocation(shader, "lightDirection")
    light_color_loc := rl.GetShaderLocation(shader, "lightColor")
    ambient_color_loc := rl.GetShaderLocation(shader, "ambientColor")

    update_shader_values(
        &light_direction, &light_color, &ambient_color,
        int(light_direction_loc), int(light_color_loc), int(ambient_color_loc), 
        shader)

    position := rl.Vector3{ 0.0, 0.0, 0.0 } // Set model position

    imgui.CreateContext(nil)
	defer imgui.DestroyContext(nil)

    // Initialize ImGui Backend
    rlimgui.init()
    defer rlimgui.shutdown()

    // Main game loop
    for !rl.WindowShouldClose() {
        // update 
        dt := rl.GetFrameTime()
        update_camera(&camera, dt)

        // call imgui
        imgui_display(&light_direction, &light_color, &ambient_color)
        update_shader_values(
            &light_direction, &light_color, &ambient_color,
            int(light_direction_loc), int(light_color_loc), int(ambient_color_loc), 
            shader)

        // render
        rl.BeginDrawing()
        rl.ClearBackground({ 20, 20, 20, 255 })

        rl.BeginMode3D(camera)
        rl.DrawGrid(20, 2.0)
        rl.DrawModel(model, position, 1.0, rl.RAYWHITE)
        rl.EndMode3D()

        imgui.Render()
		rlimgui.render_draw_data(imgui.GetDrawData())

        rl.EndDrawing()
    }
}