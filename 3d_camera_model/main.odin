package main
import rl "vendor:raylib"

SCREEN_WIDTH  :: 600
SCREEN_HEIGHT :: 600
TARGET_FPS :: 60

main :: proc() {
    // raylib window
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Raylib 3D Camera Mouse Control")
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
    position := rl.Vector3{ 0.0, 0.0, 0.0 } // Set model position

    // Main game loop
    for !rl.WindowShouldClose() {
        // update 
        dt := rl.GetFrameTime()
        update_camera(&camera, dt)

        rl.BeginDrawing()
        rl.ClearBackground({ 20, 20, 20, 255 })

        rl.BeginMode3D(camera)
        rl.DrawGrid(20, 2.0)
        rl.DrawModel(model, position, 1.0, rl.RAYWHITE)
        rl.EndMode3D()

        rl.DrawFPS(0, 0)
        rl.EndDrawing()
    }
}