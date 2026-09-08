package box3d_testing

import "core:fmt"
import rl "vendor:raylib"
import "core:strings"
import b3 "vendor:box3d"
import imgui "../../../ODIN_REPO/external_packages/odin-imgui-main"
import rlimgui "../../../ODIN_REPO/external_packages/backend/rlimgui"

WIDTH :: 800
HEIGHT :: 800
BACKGROUND :: rl.Color{ 0, 0, 28, 255 }


main :: proc() {
    // Initialize raylib
    rl.InitWindow(WIDTH, HEIGHT, "box3d")
    rl.SetTargetFPS(60)
    defer rl.CloseWindow()

    // box3d setup
    world_def := b3.DefaultWorldDef()
    world_def.gravity = rl.Vector3{ 0.0, -10.0, 0.0 } 

    // Create the physics world
    world_id := b3.CreateWorld(world_def)
    defer b3.DestroyWorld(world_id)

    // Define the static ground body
    ground_body_def := b3.DefaultBodyDef()
    ground_body_def.position = rl.Vector3{ 0.0, -2.0, 0.0 }
    ground_body_def.type = .staticBody
    ground_id := b3.CreateBody(world_id, ground_body_def)

    // Add a ground box shape
    ground_box := b3.MakeBoxHull(20.0, 2.0, 20.0)
    ground_shape_def := b3.DefaultShapeDef()
    _ = b3.CreateHullShape(ground_id, ground_shape_def, &ground_box.base)

    // floor mesh
    floor_mesh := rl.GenMeshCube(20.0, 2.0, 20.0)
    floor_model := rl.LoadModelFromMesh(floor_mesh)

    // Create a dynamic Box3d body
    body_def := b3.DefaultBodyDef()
    body_def.type = .dynamicBody
    body_def.position = rl.Vector3{ 0.0, 20.0, 0.0 } // Start 10 units high
    cube_body_id := b3.CreateBody(world_id, body_def)

    dynamic_box := b3.MakeCubeHull(1.0)
    shape_def := b3.DefaultShapeDef()
    shape_def.density = 1.0
    shape_def.baseMaterial.friction = 0.1
    
    _ = b3.CreateHullShape(cube_body_id, shape_def, &dynamic_box.base)

    b3_initialPos := b3.Body_GetPosition(cube_body_id)

    // camera
    camera := rl.Camera3D{
        position = rl.Vector3{ 40.0, 0.0, 40.0 }, // Camera position
        target = rl.Vector3{ 0.0, 0.0, 0.0 },      // Camera looking at point
        // target = b3_initialPos,      // Camera looking at point
        up = rl.Vector3{ 0.0, 1.0, 0.0 },          // Camera up vector (rotation towards target)
        fovy = f32(45.0),                                // Camera field-of-view Y
        projection = .PERSPECTIVE,
    }

    mesh := rl.GenMeshCube(2.0, 2.0, 2.0)
    model := rl.LoadModelFromMesh(mesh)

    cube_initial_pos := b3.Body_GetPosition(cube_body_id)

    imgui.CreateContext(nil)
	defer imgui.DestroyContext(nil)

    // Initialize ImGui Backend
    rlimgui.init()
    defer rlimgui.shutdown()

    f: f32
    is_editing: bool
    is_rotating: bool
    is_running: bool

    b3_pos: rl.Vector3
    b3_rot: rl.Quaternion

    current_pos: rl.Vector3
    current_rot: rl.Quaternion
    transform_matrix := rl.Matrix(1) // same as rl.MatrixIdentity() <- deprecated

    // get initial position for displaying at the beginning of the scene
    initial_pos := b3.Body_GetPosition(cube_body_id)
    initial_rot := b3.Body_GetRotation(cube_body_id)

    initial_transform := rl.MatrixTranslate(
        f32(initial_pos.x),
        f32(initial_pos.y),
        f32(initial_pos.z),
    )

    rl.DisableCursor()

    for !rl.WindowShouldClose() {
        // update
        if rl.IsKeyPressed(.SPACE){
            is_editing = !is_editing
        }
        if is_editing{
            rl.UpdateCamera(&camera, .FREE)
        }
        if rl.IsKeyPressed(.ENTER){
            is_running = !is_running
        }
        if is_running {
            // simulation by discrete time steps
			delta_time := rl.GetFrameTime()
			b3.World_Step(world_id, delta_time, 4)

            // get the latest position and orientation from Box3D
            b3_pos = b3.Body_GetPosition(cube_body_id)
            b3_rot = b3.Body_GetRotation(cube_body_id)

            // convert Box3D types to raylib/raymath types
            current_pos = { b3_pos.x, b3_pos.y, b3_pos.z }
            tmp_quaternion := quaternion(
                w = f32(b3_rot.w),
                x = f32(b3_rot.x),
                y = f32(b3_rot.y),
                z = f32(b3_rot.z),
            )
            current_rot = rl.Quaternion(tmp_quaternion)

            rotation_matrix := rl.QuaternionToMatrix(current_rot)
            translation_matrix := rl.MatrixTranslate(
                current_pos.x,
                current_pos.y,
                current_pos.z,
            )

            transform_matrix = rotation_matrix * translation_matrix
		}

        // Let the backend process mouse, keyboard, and window scaling changes
        rlimgui.process_events()
        rlimgui.new_frame() 
        imgui.NewFrame()

        imgui.SetNextWindowCollapsed(true, imgui.Cond.FirstUseEver)

        // --- Define ImGui UI Layout ---
        imgui.Begin("Debug Control Panel")
        imgui.Text("SPACE: control camera")
        imgui.Text("ENTER: start sim")

        fps:= 1.0 / rl.GetFrameTime()
        fps_text := fmt.tprintf("FPS: %.1f (%.3f ms)", fps, rl.GetFrameTime() * 1000.0)
        fps_cstring := strings.clone_to_cstring(fps_text, context.temp_allocator)
        imgui.TextUnformatted(fps_cstring)

        imgui.Text("Position:")
        imgui.SameLine()

        imgui.SetNextItemWidth(50.0)
        imgui.InputFloat("##X", &b3_pos.x)
        imgui.SameLine()

        imgui.SetNextItemWidth(50.0)
        imgui.InputFloat("##Y", &b3_pos.y)
        imgui.SameLine()

        imgui.SetNextItemWidth(50.0)
        imgui.InputFloat("##Z", &b3_pos.z)

        imgui.End()

        // render

        rl.BeginDrawing()
		rl.ClearBackground(BACKGROUND)

        rl.BeginMode3D(camera)

        if !is_running{
            model.transform = initial_transform
            rl.DrawModel(model, rl.Vector3{ 0.0, 0.0, 0.0 }, 1.0, rl.Color{ 57, 255, 20, 255 },)
            rl.DrawModelWires(model, rl.Vector3{ 0.0, 0.0, 0.0 }, 1.0, rl.RAYWHITE,)
        } else{
            model.transform = transform_matrix
            rl.DrawModel(model, rl.Vector3{ 0.0, 0.0, 0.0 }, 1.0, rl.Color{ 57, 255, 20, 255 },)
            rl.DrawModelWires(model, rl.Vector3{ 0.0, 0.0, 0.0 }, 1.0, rl.RAYWHITE,)
        }

        rl.DrawModel(floor_model, rl.Vector3{ 0.0, -1.0, 0.0 }, 1.0, rl.DARKGRAY) // shoudl be half the thickness of the floor
        // rl.DrawGrid(10, 2.0)
        rl.EndMode3D();

        imgui.Render()
		rlimgui.render_draw_data(imgui.GetDrawData())

        rl.EndDrawing()
    }
}