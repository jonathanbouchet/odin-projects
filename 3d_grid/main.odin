package threeDgrid

import "core:fmt"
import "core:mem"
import "core:math"
import rl "vendor:raylib"

import imgui "../../../ODIN_REPO/external_packages/odin-imgui-main"
import rlimgui "../../../ODIN_REPO/external_packages/backend/rlimgui"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 800
TARGET_FPS :: 60

GRID_SIZE :: 2 // should be even for a symetric grid around (0,0)
// 5 means a grid of 10 x 10, ie 5 on the positive X, 5 on the negative  ; same for Z
CELL_WIDTH :: 10
GRID_NUM_CELLS :: 16 // total number of cells
// formula is i -> (i x 2)^2

Tile :: struct {
    id: i32, // unique id
    id_row: i32, // row id on the screen grid
    id_col: i32, // col id on the screen grid
    i: i32, // "x" coordinate on the screen
    j: i32, // "y" coordinate on the screen
    status: bool, // placeholder: right now just flag if the mouse is clicked on this tile
    color: rl.Color, // base color
    color_hit: rl.Color, // color if the tile is highlighted by the mouse
    width: i32, // width of the tile ; this is not pixel
    height: i32, // height of the tile ; this is not pixel
}

// create a grid
generate_grid :: proc(grid: ^[GRID_NUM_CELLS]Tile) {
    // initialize a grid
    // ordering is from negative row -> positive row, negative col -> positive col
    // example for:
    // GRID_SIZE = 2, GRID_NUM_CELLS = 16
    // 0  1  2  3
    // 4  5  6  7
    // 8  9  10 11
    // 12 13 14 15
    counter := i32(0)

    model := rl.LoadModelFromMesh(rl.GenMeshCube(CELL_WIDTH, 0.01, CELL_WIDTH))
    base_bounding_box := rl.GetModelBoundingBox(model)

    for jj in 0..<2 * GRID_SIZE {
        for ii in 0..<2 * GRID_SIZE {
            tile := Tile{
                id = counter,
                id_row = i32(jj),
                id_col = i32(ii),
                // i = i32(GRID_CELL * ii + 1) - GRID_CELL * GRID_SIZE ,
                // j = i32(GRID_CELL * jj + 1) - GRID_CELL * GRID_SIZE,
                i = i32(-CELL_WIDTH * GRID_SIZE + ii*CELL_WIDTH),
                j = i32(-CELL_WIDTH * GRID_SIZE + jj*CELL_WIDTH),
                status = false,
                color = rl.Color{ 0, 0, 28, 255 },
                color_hit = rl.GREEN,
                width = i32(CELL_WIDTH),
                height = i32(CELL_WIDTH)
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
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "3D model")
    defer rl.CloseWindow()

    // camera
    camera := rl.Camera3D{
        position   = { 0.0, 8.0, 10.0 },
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

    imgui.CreateContext(nil)
	defer imgui.DestroyContext(nil)

    // Initialize ImGui Backend
    rlimgui.init()
    defer rlimgui.shutdown()

    // models
    model := rl.LoadModelFromMesh(rl.GenMeshCube(CELL_WIDTH, 0.01, CELL_WIDTH))
    defer rl.UnloadModel(model)
    model_house := rl.LoadModel("assets/building_A.gltf")
    defer rl.UnloadModel(model_house)

    tileSize := CELL_WIDTH
    gridX: i32
    gridZ: i32

    // Main game loop
    for !rl.WindowShouldClose() {
        // update 
        dt := rl.GetFrameTime()
        update_camera(&camera, dt)

        // logic
        mouse_pos := rl.GetMousePosition()
        ray := rl.GetScreenToWorldRay(mouse_pos, camera)
        groundY := f32(0.0)

        // Ray: position + direction * t
        // Find t where the ray reaches y = groundY:
        // ray.position.y + ray.direction.y * t = groundY

        groundPosition := rl.Vector3{ 0.0, 0.0, 0.0 }

        if math.abs(ray.direction.y)> 0.0001 {
            t := (groundY - ray.position.y) / ray.direction.y
            if t > 0.0 {
                groundPosition = ray.position + ray.direction * t
            }
            gridX = i32(math.floor_f32(groundPosition.x / f32(tileSize)))
            gridZ = i32(math.floor_f32(groundPosition.z / f32(tileSize)))
            for i in 0..<len(grid) {
                if gridX == grid[i].id_col - GRID_SIZE && gridZ == grid[i].id_row - GRID_SIZE {
                    if rl.IsMouseButtonPressed(.LEFT) {
                        grid[i].status = true
                    }
                }
            }
        }

        // call imgui
        imgui_display(mouse_pos, gridX, gridZ)

        // hit := rl.GetRayCollisionBox(ray, bb)

        // if hit.hit{
        //     worldPosition := hit.point
        //     // fmt.printfln("world position: %v", worldPosition)
        //     is_hit = true
        // }

        // render
        rl.BeginDrawing()
        rl.ClearBackground(rl.Color{ 20, 20, 20, 255 })

        rl.BeginMode3D(camera)
        for i in 0..<len(grid) {

            tmp_pos := rl.Vector3{f32( grid[i].i + CELL_WIDTH/2), -0.02, f32(grid[i].j + CELL_WIDTH/2) }
            
            if gridX == grid[i].id_col - GRID_SIZE && gridZ == grid[i].id_row - GRID_SIZE {
                rl.DrawModel(model, tmp_pos, 1.0, grid[i].color_hit)
            } else {
                rl.DrawModel(model, tmp_pos, 1.0, grid[i].color)
            }
            // show the model if it has been seelcted
            if grid[i].status {
                scaling_factor := f32(CELL_WIDTH / GRID_SIZE)
                rl.DrawModelEx(model_house, tmp_pos, rl.Vector3{ 0.0, 0.0, 0.0 }, 0.0, rl.Vector3{ scaling_factor, scaling_factor, scaling_factor }, rl.RAYWHITE)
            }
        }


        rl.DrawGrid(10, CELL_WIDTH)
        rl.DrawLine3D(rl.Vector3{ 0.0, 0.01, -10.0 }, rl.Vector3{ 0.0, 0.01, 10.0 }, rl.DARKBLUE )
        rl.DrawLine3D(rl.Vector3{ -10.0, 0.01, 0.0 }, rl.Vector3{ 10.0, 0.01, 0.0 }, rl.DARKBLUE )
        rl.EndMode3D()

        imgui.Render()
		rlimgui.render_draw_data(imgui.GetDrawData())

        // grid_pos_text := fmt.ctprintf("i:%v j:%v", gridX, gridZ)
        // rl.DrawFPS(0, 0)
        // rl.DrawText(grid_pos_text, 0, 20, 20, rl.GREEN)
        // mouse_pos_text := fmt.ctprintf("X:%.1f Y:%.1f", rl.GetMousePosition().x, rl.GetMousePosition().y)
        // rl.DrawText(mouse_pos_text, 0, 40, 20, rl.GREEN)

        rl.EndDrawing()
    }
}