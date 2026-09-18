package threeDgrid

import "core:fmt"
import "core:mem"
import "core:math"
import rl "vendor:raylib"

import imgui "../../../ODIN_REPO/external_packages/odin-imgui-main"
import rlimgui "../../../ODIN_REPO/external_packages/backend/rlimgui"

SCREEN_WIDTH :: 600
SCREEN_HEIGHT :: 600
TARGET_FPS :: 60

GRID_SIZE :: 2
GRID_CELL :: 2

Tile :: struct {
    i: i32,
    j: i32,
    x: f32,
    y: f32,
    z: f32,
    status: bool,
    color: rl.Color,
    width: i32,
    height: i32,
    bb: rl.BoundingBox
}

grid: [GRID_SIZE*GRID_SIZE]Tile

// create a grid
generate_grid :: proc() {
    min_i := GRID_SIZE / 2 - GRID_SIZE
    min_j : = GRID_SIZE / 2 - GRID_SIZE
    fmt.printfln("min_i: %d, min_j: %d", min_i, min_j)
    counter := i32(0)

    model := rl.LoadModelFromMesh(rl.GenMeshCube(GRID_CELL, 0.01, GRID_CELL))
    base_bounding_box := rl.GetModelBoundingBox(model)

    for i in min_i..<GRID_SIZE - 1{
        for j in min_j..<GRID_SIZE - 1{
            fmt.printfln("i: %d, j: %d", i, j)
            tmp_bb := base_bounding_box
            tmp_bb.min += rl.Vector3{ f32(i*GRID_CELL), f32(0.01), f32(j*GRID_CELL)}
            tmp_bb.max += rl.Vector3{ f32(i*GRID_CELL), f32(0.01), f32(j*GRID_CELL)}
            tile := Tile{
                i = i32(i),
                j = i32(j),
                x = f32(i*GRID_CELL),
                y = f32(0.01),
                z = f32(j*GRID_CELL),
                status = false,
                color = rl.DARKGRAY,
                width = i32(GRID_CELL),
                height = i32(GRID_CELL),
                bb = tmp_bb
            }
            grid[counter] = tile
            counter += 1
        }        
    }
}


show_memory :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer {
        for _, entry in track.allocation_map {
            fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
        }
        for entry in track.bad_free_array {
            fmt.eprintf("%v bad free\n", entry.location)
        }
        mem.tracking_allocator_destroy(&track)
    }
}

main :: proc() {
    show_memory()
    // raylib window
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "3D model")
    defer rl.CloseWindow()

    // camera
    camera := rl.Camera3D{
        position   = { 0.0, 4.0, 10.0 },
        target     = { 0.0, 0.0, 0.0 },
        up         = { 0.0, 1.0, 0.0 },
        fovy       = 60.0,
        projection = .PERSPECTIVE,
    }
    rl.SetTargetFPS(TARGET_FPS)
    // grid
    generate_grid()
    fmt.printfln("grid length: %v", len(grid))
    fmt.printfln("grid[0]: %v", grid[0])

    imgui.CreateContext(nil)
	defer imgui.DestroyContext(nil)

    // Initialize ImGui Backend
    rlimgui.init()
    defer rlimgui.shutdown()

    // models
    model := rl.LoadModelFromMesh(rl.GenMeshCube(2.0, 0.01, 2.0))
    bb := rl.GetModelBoundingBox(model)
    fmt.printfln("bb: %v", bb)
    position := rl.Vector3{ 1.0, 0.01, 1.0 } // center of the cube so it will appear at gridX=0, gridZ=0 if W,H,L = 2
    // need to update BB if position is shifted from 0, 0, 0
    bb.min += position
    bb.max += position
    tileSize := 2
    gridX: i32
    gridZ: i32
    is_hit: bool

    // Main game loop
    for !rl.WindowShouldClose() {
        // update 
        dt := rl.GetFrameTime()
        update_camera(&camera, dt)

        // call imgui
        imgui_display()

        // logic
        is_hit = false
        mouse_pos := rl.GetMousePosition()
        ray := rl.GetScreenToWorldRay(mouse_pos, camera)
        groundY := f32(0.0)

        // Ray: position + direction * t
        // Find t where the ray reaches y = groundY:
        // ray.position.y + ray.direction.y * t = groundY

        groundPosition := rl.Vector3{ 0.0, 0.0, 0.0 }

        if math.abs(ray.direction.y)> 0.0001{
            t := (groundY - ray.position.y) / ray.direction.y
            if t > 0.0{
                groundPosition = ray.position + ray.direction * t
            }
            gridX = i32(math.floor_f32(groundPosition.x / f32(tileSize)))
            gridZ = i32(math.floor_f32(groundPosition.z / f32(tileSize)))
            // fmt.printfln("gridX, gridY: %v %v", gridX, gridZ)
        }

        hit := rl.GetRayCollisionBox(ray, bb)

        if hit.hit{
            worldPosition := hit.point
            fmt.printfln("world position: %v", worldPosition)
            is_hit = true
        }

        // render
        rl.BeginDrawing()
        rl.ClearBackground({ 20, 20, 20, 255 })

        rl.BeginMode3D(camera)
        rl.DrawModel(model, position, 1.0, rl.GREEN if is_hit else rl.RED)
        rl.DrawCubeWires(position, 2.0, 0.01, 2.0, rl.GREEN if is_hit else rl.GRAY)
        rl.DrawGrid(10, 2.0)
        rl.DrawLine3D(rl.Vector3{ 0.0, 0.01, -10.0 }, rl.Vector3{ 0.0, 0.01, 10.0 }, rl.DARKBLUE )
        rl.DrawLine3D(rl.Vector3{ -10.0, 0.01, 0.0 }, rl.Vector3{ 10.0, 0.01, 0.0 }, rl.DARKBLUE )
        rl.EndMode3D()

        imgui.Render()
		rlimgui.render_draw_data(imgui.GetDrawData())

        grid_pos_text := fmt.ctprintf("X:%v Z:%v", gridX, gridZ)
        is_detected_text := fmt.ctprintf("Mouse Hover: %v", is_hit)
        rl.DrawFPS(0, 0)
        rl.DrawText(grid_pos_text, 0, 20, 20, rl.GREEN)
        rl.DrawText(is_detected_text, 0, 40, 20, rl.GREEN)

        rl.EndDrawing()
    }
}