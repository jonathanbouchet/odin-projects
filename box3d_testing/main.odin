package box3d_testing

import "core:fmt"
import rl "vendor:raylib"
import "core:strings"
import b3 "vendor:box3d"
import imgui "../../../ODIN_REPO/external_packages/odin-imgui-main"
import rlimgui "../../../ODIN_REPO/external_packages/backend/rlimgui"

WIDTH :: 600
HEIGHT :: 600
BACKGROUND :: rl.Color{110, 184, 168, 255}

imgui_display :: proc(position: ^rl.Vector3, sphere_position: ^rl.Vector3, gravity: ^rl.Vector3) {
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

        imgui.Text("Gravity:")
        imgui.SameLine()

        imgui.SetNextItemWidth(50.0)
        imgui.InputFloat("##x", &gravity.x)
        imgui.SameLine()

        imgui.SetNextItemWidth(50.0)
        imgui.InputFloat("##y", &gravity.y)
        imgui.SameLine()

        imgui.SetNextItemWidth(50.0)
        imgui.InputFloat("##z", &gravity.z)

        imgui.Text("Cube Position:")
        imgui.SameLine()

        imgui.SetNextItemWidth(50.0)
        imgui.InputFloat("##x", &position.x)
        imgui.SameLine()

        imgui.SetNextItemWidth(50.0)
        imgui.InputFloat("##y", &position.y)
        imgui.SameLine()

        imgui.SetNextItemWidth(50.0)
        imgui.InputFloat("##z", &position.z)

        imgui.Text("Sphere Position:")
        imgui.SameLine()

        imgui.SetNextItemWidth(50.0)
        imgui.InputFloat("##x", &sphere_position.x)
        imgui.SameLine()

        imgui.SetNextItemWidth(50.0)
        imgui.InputFloat("##y", &sphere_position.y)
        imgui.SameLine()

        imgui.SetNextItemWidth(50.0)
        imgui.InputFloat("##z", &sphere_position.z)

        imgui.End()
}

get_body_transform :: proc(id: b3.BodyId) -> rl.Matrix {
    pos := b3.Body_GetPosition(id)
    rot := b3.Body_GetRotation(id)
    // convert Box3D types to raylib/raymath types

    pos_rl := rl.Vector3{ pos.x, pos.y, pos.z }
    quaternion_rl := quaternion(
        w = f32(rot.w),
        x = f32(rot.x),
        y = f32(rot.y),
        z = f32(rot.z),
    )
    rot_rl := rl.Quaternion(quaternion_rl)

    rotation_matrix := rl.QuaternionToMatrix(rot_rl)
    translation_matrix := rl.MatrixTranslate(
        pos_rl.x,
        pos_rl.y,
        pos_rl.z,
    )
    transform_matrix := rotation_matrix * translation_matrix
    return transform_matrix
}

entity :: struct {
    id: b3.BodyId,
    model: rl.Model
}

create_box :: proc(position: rl.Vector3, world_id: b3.WorldId) -> b3.BodyId {
    // Create a dynamic Box3d body
    body_def := b3.DefaultBodyDef()
    body_def.type = .dynamicBody
    body_def.position = position
    cube_body_id := b3.CreateBody(world_id, body_def)

    dynamic_box := b3.MakeCubeHull(1.0)
    shape_def := b3.DefaultShapeDef()
    shape_def.density = 1.0
    shape_def.baseMaterial.friction = 0.2
    shape_def.baseMaterial.restitution = 0.1
    
    _ = b3.CreateHullShape(cube_body_id, shape_def, &dynamic_box.base)
    return cube_body_id
} 

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

    // create dynamic boxes
    entity_1_id := create_box(position=rl.Vector3{-6.0, 2.0, -6.0}, world_id=world_id)
    entity_2_id := create_box(position=rl.Vector3{-6.0, 2.0, -3.0}, world_id=world_id)
    entity_3_id := create_box(position=rl.Vector3{-6.0, 2.0, 0.0}, world_id=world_id)

    entity_4_id := create_box(position=rl.Vector3{-6.0, 5.0, -4.5}, world_id=world_id)
    entity_5_id := create_box(position=rl.Vector3{-6.0, 5.0, -1.5}, world_id=world_id)

    entity_6_id := create_box(position=rl.Vector3{-6.0, 8.0, -3.0}, world_id=world_id)

    mesh := rl.GenMeshCube(2.0, 2.0, 2.0)
    model := rl.LoadModelFromMesh(mesh)

    boxes_pos: [6]rl.Vector3
    boxes_id := [6]b3.BodyId{
        entity_1_id,
        entity_2_id,
        entity_3_id,
        entity_4_id,
        entity_5_id,
        entity_6_id,
    }

    // Create a dynamic Box3d sphere
    sphere_radius := f32(1.0)
    sphere := b3.Sphere{ radius = sphere_radius }

    sphere_shape_def := b3.DefaultShapeDef()
    sphere_shape_def.density = 1.0
    sphere_shape_def.baseMaterial.friction = 0.25
    sphere_shape_def.baseMaterial.restitution = 0.75

    sphere_body_def := b3.DefaultBodyDef()
    sphere_body_def.type = .dynamicBody
    sphere_body_def.position = rl.Vector3{ 5.0, 5.0, -3.0 }
    sphere_body_def.linearVelocity = rl.Vector3 {-30, 0, 0}

    sphere_body_id := b3.CreateBody(world_id, sphere_body_def)
    _ = b3.CreateSphereShape(sphere_body_id, sphere_shape_def, &sphere)

    sphere_mesh := rl.GenMeshSphere(sphere_radius, 10, 20)
    sphere_model := rl.LoadModelFromMesh(sphere_mesh)

    // camera
    camera := rl.Camera3D{
        position = rl.Vector3{ 40.0, 15.0, 40.0 }, // Camera position
        target = rl.Vector3{ 0.0, 10.0, 0.0 },      // Camera looking at point
        // target = b3_initialPos,      // Camera looking at point
        up = rl.Vector3{ 0.0, 1.0, 0.0 },          // Camera up vector (rotation towards target)
        fovy = f32(45.0),                                // Camera field-of-view Y
        projection = .PERSPECTIVE,
    }

    imgui.CreateContext(nil)
	defer imgui.DestroyContext(nil)

    // Initialize ImGui Backend
    rlimgui.init()
    defer rlimgui.shutdown()

    is_editing: bool
    is_running: bool
    is_shoot: bool
    current_pos: rl.Vector3
    sphere_pos : rl.Vector3
    transform_matrix := rl.Matrix(1) // same as rl.MatrixIdentity() <- deprecated
    transform_matrix_sphere := rl.Matrix(1) // same as rl.MatrixIdentity() <- deprecated
  
    rl.DisableCursor()

    for !rl.WindowShouldClose() {
        // update
        if rl.IsKeyPressed(.SPACE) {
            is_editing = !is_editing
        }
        if is_editing {
            rl.UpdateCamera(&camera, .FREE)
        }
        if rl.IsKeyPressed(.ENTER) {
            is_running = !is_running
        }
        if is_running {
            // simulation by discrete time steps
			delta_time := rl.GetFrameTime()
			b3.World_Step(world_id, delta_time, 4)
		} 
        // if rl.IsKeyPressed(.S) {
        //     is_shoot = !is_shoot
        // }
        // if is_shoot {
        //     // sphere is not subject to physics at the beginning of the scene
        //     // if triggered by KB, it is added to the world
		// 	delta_time := rl.GetFrameTime()
        //     // sphere_body_id := b3.CreateBody(world_id, sphere_body_def)
        //     _ = b3.CreateSphereShape(sphere_body_id, sphere_shape_def, &sphere)
		// 	b3.World_Step(world_id, delta_time, 4)
		// } 

        // render
        for i in 0..<len(boxes_id) {
            boxes_pos[i] = b3.Body_GetPosition(boxes_id[i])
        }
        sphere_pos = b3.Body_GetPosition(sphere_body_id)
        imgui_display(&current_pos, &sphere_pos, &world_def.gravity)

        rl.BeginDrawing()
		rl.ClearBackground(BACKGROUND)

        rl.BeginMode3D(camera)

        // cube
        for i in 0..<len(boxes_pos) {
            model.transform = get_body_transform(boxes_id[i])
            rl.DrawModel(model, rl.Vector3{ 0.0, 0.0, 0.0 }, 1.0, rl.Color{ 57, 255, 20, 255 },)
            rl.DrawModelWires(model, rl.Vector3{ 0.0, 0.0, 0.0 }, 1.0, rl.BLACK,)
        }
        // sphere
        sphere_model.transform = get_body_transform(sphere_body_id)
        rl.DrawModel(sphere_model, rl.Vector3{ 0.0, 0.0, 0.0 }, 1.0, rl.Color{ 255, 240, 30, 255 },)
        // rl.DrawModelWires(sphere_model, rl.Vector3{ 0.0, 0.0, 0.0 }, 1.0, rl.RAYWHITE,)

        // floor
        rl.DrawModel(floor_model, rl.Vector3{ 0.0, -1.0, 0.0 }, 1.0, rl.Color{0, 0, 28, 255}) // should be half the thickness of the floor
        rl.DrawGrid(10, 2.0)
        rl.EndMode3D();

        imgui.Render()
		rlimgui.render_draw_data(imgui.GetDrawData())

        rl.EndDrawing()
    }
}