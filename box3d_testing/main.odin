package box3d_testing

import "core:fmt"
import rl "vendor:raylib"
import "core:strings"
import b3 "vendor:box3d"
import imgui "../../../ODIN_REPO/external_packages/odin-imgui-main"
import rlimgui "../../../ODIN_REPO/external_packages/backend/rlimgui"

WIDTH :: 800
HEIGHT :: 800
BACKGROUND :: rl.Color{0, 0, 28, 255}


main :: proc(){
    // Initialize raylib
    rl.InitWindow(WIDTH, HEIGHT, "box3d")
    rl.SetTargetFPS(60)
    defer rl.CloseWindow()

    // box3d setup
    worldDef := b3.DefaultWorldDef()
    worldDef.gravity = rl.Vector3{0.0, -10.0, 0.0} 

    // Create the physics world
    worldId := b3.CreateWorld(worldDef)
    defer b3.DestroyWorld(worldId)

    // Define the static ground body
    groundBodyDef := b3.DefaultBodyDef()
    groundBodyDef.type = .staticBody
    position := rl.Vector3{0.0, 0.0, 0.0}
    groundId := b3.CreateBody(worldId, groundBodyDef)

    // Add a ground box shape
    groundBox := b3.MakeBoxHull(50.0, 2.0, 50.0)
    groundShapeDef := b3.DefaultShapeDef()
    _ = b3.CreateHullShape(groundId, groundShapeDef, &groundBox.base)

    // Create a dynamic Box3d body
    bodyDef := b3.DefaultBodyDef()
    bodyDef.type = .dynamicBody
    bodyDef.position = rl.Vector3{0.0, 20.0, 0.0} // Start 10 units high
    cubeBodyId := b3.CreateBody(worldId, bodyDef)

    dynamicBox := b3.MakeCubeHull(1.0)
    shapeDef := b3.DefaultShapeDef()
    shapeDef.density = 1.0
    shapeDef.baseMaterial.friction = 0.1
    
    _ = b3.CreateHullShape(cubeBodyId, shapeDef, &dynamicBox.base)

    b3_initialPos := b3.Body_GetPosition(cubeBodyId)

    // camera
    camera := rl.Camera3D{
        position = rl.Vector3{ 40.0, 10.0, 40.0 }, // Camera position
        target = rl.Vector3{ 0.0, 0.0, 0.0 },      // Camera looking at point
        // target = b3_initialPos,      // Camera looking at point
        up = rl.Vector3{ 0.0, 1.0, 0.0 },          // Camera up vector (rotation towards target)
        fovy = f32(45.0),                                // Camera field-of-view Y
        projection = .PERSPECTIVE,
    }

    mesh := rl.GenMeshCube(2.0, 2.0, 2.0)
    model := rl.LoadModelFromMesh(mesh)

    cube_initial_pos := b3.Body_GetPosition(cubeBodyId)

    imgui.CreateContext(nil)
	defer imgui.DestroyContext(nil)

    // Initialize ImGui Backend
    rlimgui.init()
    defer rlimgui.shutdown()

    f: f32
    is_editing: bool
    rotation: f32
    is_rotating: bool
    is_running: bool

    b3Pos: rl.Vector3
    b3Rot: rl.Quaternion

    current_pos: rl.Vector3
    current_rot: rl.Quaternion
    transform_matrix := rl.Matrix(1) // same as rl.MatrixIdentity(), but deprecated

    // initial position
    initial_pos := b3.Body_GetPosition(cubeBodyId)
    initial_rot := b3.Body_GetRotation(cubeBodyId)

    initial_transform := rl.MatrixTranslate(
        f32(initial_pos.x),
        f32(initial_pos.y),
        f32(initial_pos.z),
    )

    rl.DisableCursor()

    for !rl.WindowShouldClose() {
        // --- Update & Event Handling ---
        if rl.IsKeyPressed(.SPACE){
            is_editing = !is_editing
        }
        if is_editing{
            rl.UpdateCamera(&camera, .FREE)
        }
        if rl.IsKeyPressed(.R){
            is_rotating = !is_rotating
        }
        if is_rotating{
            dt := rl.GetFrameTime()
            rotation += 100 * dt
        }
        if rl.IsKeyPressed(.ENTER){
            is_running = !is_running
        }
        if is_running {
            // simulation by discrete time steps
			delta_time := rl.GetFrameTime()
			b3.World_Step(worldId, delta_time, 4)

            // get the latest position and orientation from Box3D
            b3Pos = b3.Body_GetPosition(cubeBodyId)
            b3Rot = b3.Body_GetRotation(cubeBodyId)

            // convert Box3D types to raylib/raymath types
            current_pos = {b3Pos.x, b3Pos.y, b3Pos.z}
            tmp_quaternion := quaternion(
                w = f32(b3Rot.w),
                x = f32(b3Rot.x),
                y = f32(b3Rot.y),
                z = f32(b3Rot.z),
            )
            current_rot = rl.Quaternion(tmp_quaternion)

            rotation_matrix := rl.QuaternionToMatrix(current_rot)
            translation_matrix := rl.MatrixTranslate(
                current_pos.x,
                current_pos.y,
                current_pos.z,
            )

            transform_matrix = rotation_matrix * translation_matrix

            fmt.printf("position: %v\n", b3Pos)
		}

        // Let the backend process mouse, keyboard, and window scaling changes
        rlimgui.process_events()
        rlimgui.new_frame() 
        imgui.NewFrame()

        imgui.SetNextWindowCollapsed(true, imgui.Cond.FirstUseEver)

        // --- Define ImGui UI Layout ---
        imgui.Begin("Debug Control Panel")
        imgui.Text("SPACE: camera")
        imgui.Text("R: rotate cube")
        imgui.Text("ENTER: start sim")

        fps:= 1.0 / rl.GetFrameTime()
        fps_text := fmt.tprintf("FPS: %.1f (%.3f ms)", fps, rl.GetFrameTime() * 1000.0)
        fps_cstring := strings.clone_to_cstring(fps_text, context.temp_allocator)
        imgui.TextUnformatted(fps_cstring)

        imgui.Text("Position:")
        imgui.SameLine()

        imgui.SetNextItemWidth(50.0)
        imgui.InputFloat("##X", &b3Pos.x)
        imgui.SameLine()

        imgui.SetNextItemWidth(50.0)
        imgui.InputFloat("##Y", &b3Pos.y)
        imgui.SameLine()

        imgui.SetNextItemWidth(50.0)
        imgui.InputFloat("##Z", &b3Pos.z)

        imgui.Text("Rotation:")
        imgui.SameLine()
        imgui.SetNextItemWidth(75.0)
        imgui.InputFloat("##Y", &rotation)

        imgui.End()

        rl.BeginDrawing()
		rl.ClearBackground(BACKGROUND)

        rl.BeginMode3D(camera)

        model.transform = transform_matrix

        if !is_running{
            model.transform = initial_transform
            rl.DrawModel(model, rl.Vector3{0.0, 0.0, 0.0}, 1.0, rl.Color{57, 255, 20, 255},)
            rl.DrawModelWires(model, rl.Vector3{0.0, 0.0, 0.0}, 1.0, rl.RAYWHITE,)
        } else{
            model.transform = transform_matrix
            rl.DrawModel(model, rl.Vector3{0.0, 0.0, 0.0}, 1.0, rl.Color{57, 255, 20, 255},)
            rl.DrawModelWires(model, rl.Vector3{0.0, 0.0, 0.0}, 1.0, rl.RAYWHITE,)
        }
       
        rl.DrawGrid(10, 2.0)
        rl.EndMode3D();

        imgui.Render()
		rlimgui.render_draw_data(imgui.GetDrawData())

        rl.EndDrawing()
    }
}