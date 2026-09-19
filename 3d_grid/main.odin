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

GRID_SIZE :: 5 // should be even for a symetric grid around (0,0)
GRID_CELL :: 2
GRID_NUM_CELLS :: 100

Tile :: struct {
    id: i32,
    id_row: i32,
    id_col: i32,
    i: i32,
    j: i32,
    status: bool,
    color: rl.Color,
    color_hit: rl.Color,
    width: i32,
    height: i32,
    bb: rl.BoundingBox
}

// create a grid
generate_grid :: proc(grid: ^[GRID_NUM_CELLS]Tile) {
    // min_i := GRID_SIZE / 2 - GRID_SIZE
    // min_j : = GRID_SIZE / 2 - GRID_SIZE
    // fmt.printfln("min_i: %d, min_j: %d", min_i, min_j)
    counter := i32(0)

    model := rl.LoadModelFromMesh(rl.GenMeshCube(GRID_CELL, 0.01, GRID_CELL))
    base_bounding_box := rl.GetModelBoundingBox(model)

    for jj in 0..<2*GRID_SIZE {
        for ii in 0..<2*GRID_SIZE {
            // fmt.printfln("ii: %d, jj: %d", ii, jj)
            // tmp_bb := base_bounding_box
            // tmp_bb.min += rl.Vector3{ f32(i*GRID_CELL), f32(0.01), f32(j*GRID_CELL)}
            // tmp_bb.max += rl.Vector3{ f32(i*GRID_CELL), f32(0.01), f32(j*GRID_CELL)}
            tile := Tile{
                id = counter,
                id_row = i32(jj),
                id_col = i32(ii),
                i = i32(2*ii + 1) - 2*GRID_SIZE,
                j = i32(2*jj + 1) - 2*GRID_SIZE,
                status = false,
                color = rl.Color{ 0, 0, 28, 255 },
                color_hit = rl.GREEN,
                width = i32(GRID_CELL),
                height = i32(GRID_CELL),
                // bb = tmp_bb
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
    grid: [GRID_NUM_CELLS]Tile
    generate_grid(&grid)
    fmt.printfln("grid length: %v", len(grid))
    for gr in grid {
        fmt.printfln("grid: %v", gr)
    }
    // fmt.printfln("grid: %v", grid)

    imgui.CreateContext(nil)
	defer imgui.DestroyContext(nil)

    // Initialize ImGui Backend
    rlimgui.init()
    defer rlimgui.shutdown()

    // models
    model := rl.LoadModelFromMesh(rl.GenMeshCube(2.0, 0.01, 2.0))
    bb := rl.GetModelBoundingBox(model)
    fmt.printfln("bb: %v", bb)
    position := rl.Vector3{ 1.0, -0.01, 1.0 } // center of the cube so it will appear at gridX=0, gridZ=0 if W,H,L = 2
    // need to update BB if position is shifted from 0, 0, 0
    bb.min += position
    bb.max += position
    tileSize := 2
    gridX: i32
    gridZ: i32
    is_hit: bool

    position2 := rl.Vector3{ 3.0, 0.01, 1.0 } // center of the cube so it will appear at gridX=0, gridZ=0 if W,H,L = 2

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
            // fmt.printfln("world position: %v", worldPosition)
            is_hit = true
        }

        // render
        rl.BeginDrawing()
        rl.ClearBackground({ 20, 20, 20, 255 })

        rl.BeginMode3D(camera)
        for i in 0..<len(grid) {
            tmp_bb := grid[i].bb
            tmp_pos := rl.Vector3 {f32(grid[i].i), -0.02, f32(grid[i].j)}
            tmp_col := grid[i].color
            // if gridX == grid[i].i && gridZ == grid[i].j {
            // if gridX + 2 + gridZ + 2 == grid[i].id {
            if gridX == grid[i].id_col - GRID_SIZE && gridZ == grid[i].id_row - GRID_SIZE {
                rl.DrawModel(model, tmp_pos, 1.0, grid[i].color_hit)
            } else {
                rl.DrawModel(model, tmp_pos, 1.0, tmp_col)
            }
            // rl.DrawCubeWires(tmp_pos, 2.0, 0.1, 2.0, rl.RED)
        }
        // rl.DrawModel(model, position, 1.0, rl.GREEN if is_hit else rl.RED)
        // rl.DrawCubeWires(position, 2.0, 0.01, 2.0, rl.GREEN if is_hit else rl.GRAY)

        // rl.DrawModel(model, position2, 1.0, rl.SKYBLUE)
        // rl.DrawCubeWires(position2, 2.0, 0.01, 2.0, rl.YELLOW)


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
        mouse_pos_text := fmt.ctprintf("X:%v Y:%v", rl.GetMousePosition().x, rl.GetMousePosition().y)
        rl.DrawText(mouse_pos_text, 0, 40, 20, rl.GREEN)
        // rl.DrawText(is_detected_text, 0, 40, 20, rl.GREEN)

        rl.EndDrawing()
    }
}