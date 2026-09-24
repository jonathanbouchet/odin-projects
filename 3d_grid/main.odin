package threeDgrid

import "core:os"
import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:math"
import rl "vendor:raylib"

import imgui "../../../ODIN_REPO/external_packages/odin-imgui-main"
import rlimgui "../../../ODIN_REPO/external_packages/backend/rlimgui"

SCREEN_WIDTH :: 1000
SCREEN_HEIGHT :: 1000
TARGET_FPS :: 60

GRID_SIZE :: 2 // should be even for a symetric grid around (0,0)
// 5 means a grid of 10 x 10, ie 5 on the positive X, 5 on the negative  ; same for Z
CELL_WIDTH :: 4
GRID_NUM_CELLS :: 16 // total number of cells
// formula is i -> (i x 2)^2

Tile_Input_Data :: struct {
    tile_id: []i32,
    tile_rotation: []f32,
    tile_name: []cstring,
    tile_name_kenney: []cstring,
    tile_rotation_kenney: []f32,
    tile_name_city: []cstring,
    tile_rotation_city: []f32,
}

read_input_data :: proc(filepath: string) -> Tile_Input_Data {
    file_data, ok := os.read_entire_file(filepath, context.allocator)
    if ok != nil {
        fmt.eprintln("Failed to read file.")
        empty_data: Tile_Input_Data
        return empty_data
	}

	data: Tile_Input_Data
	err := json.unmarshal(file_data, &data)
	if err != nil {
		fmt.eprintln("Parsing error:", err)
	}
    return data
}

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

    for jj in 0..<2 * GRID_SIZE {
        for ii in 0..<2 * GRID_SIZE {
            tile := Tile{
                id = counter,
                id_row = i32(jj),
                id_col = i32(ii),
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
    rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "3D model")
    defer rl.CloseWindow()

    // read input data
    map_data := read_input_data("map.json")
    fmt.printfln("map data: %v", map_data)

    models: [3]rl.Model
    texture := rl.LoadTexture("assets/city_assets/texture/colorpaletteupdated.png")
    defer rl.UnloadTexture(texture)
    rl.GenTextureMipmaps(&texture)
    rl.SetTextureFilter(texture, .TRILINEAR)

    if texture.id == 0 {
        fmt.println("Failed to load replacement texture")
    }

    // for citybits
    // texture png is already loaded as citybits_texture.png
    // for item, i in map_data.tile_name{
    //     fmt.printfln("loading %v at position %v", item, i)
    //     models[i] = rl.LoadModel(item)
    // }

    //for city_assets
    for item, i in map_data.tile_name_city{
        fmt.printfln("loading %v at position %v", item, i)
        models[i] = rl.LoadModel(item)
        fmt.printfln("number of materials: %v", models[i].materialCount)
        for j in 0..<models[i].materialCount {
            models[i].materials[j].maps[rl.MaterialMapIndex.ALBEDO].texture = texture
        }
    }

    // camera
    camera := rl.Camera3D{
        position   = { 0.0, 20.0, 20.0 },
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

    // car: testing cityassets
    car := rl.LoadModel("assets/city_assets/GLB/sedan.glb")
    for i in 0..<car.materialCount {
        car.materials[i].maps[rl.MaterialMapIndex.ALBEDO].texture = texture
    }
    defer rl.UnloadModel(car)

    // car: testing citybits
    // car := rl.LoadModel("assets/car_stationwagon.gltf")
    // defer rl.UnloadModel(car)
    spawn_car: bool

    tileSize := CELL_WIDTH
    gridX: i32
    gridZ: i32

    // shaders
    shader := rl.LoadShader("shaders/basic.vs", "shaders/basic.fs")
    for model in models{
        for i in 0..<int(model.materialCount){
            model.materials[i].shader = shader
        }
    }
    // car
    for i in 0..<car.materialCount{
        car.materials[i].shader = shader
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

        if rl.IsKeyPressed(.ENTER){
            spawn_car = !spawn_car
        }

        // call imgui
        // imgui_display(mouse_pos, gridX, gridZ)
        imgui_display(mouse_pos, gridX, gridZ, &light_direction, &light_color, &ambient_color)
        // fmt.printfln("light direction: %v", light_direction)
        update_shader_values(
            &light_direction, &light_color, &ambient_color,
            int(light_direction_loc), int(light_color_loc), int(ambient_color_loc), 
            shader)


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

            pos_model := rl.Vector3{f32( grid[i].i + CELL_WIDTH/2), 0.1, f32(grid[i].j + CELL_WIDTH/2) }
            pos := rl.Vector3{f32( grid[i].i + CELL_WIDTH/2), -0.01, f32(grid[i].j + CELL_WIDTH/2) }
            
            if gridX == grid[i].id_col - GRID_SIZE && gridZ == grid[i].id_row - GRID_SIZE {
                rl.DrawModel(model, pos, 1.0, grid[i].color_hit)
            } else {
                rl.DrawModel(model, pos, 1.0, grid[i].color)
            }
            // show the model if it has been selected
            if grid[i].status {
                // scaling_factor := f32(CELL_WIDTH / GRID_SIZE) // citybits scaling factor
                // rl.DrawModelEx(
                //         models[map_data.tile_id[i]],
                //         pos_model, 
                //         rl.Vector3{ 0.0, 1.0, 0.0 }, 
                //         map_data.tile_rotation[i],
                //         rl.Vector3{ scaling_factor, scaling_factor, scaling_factor }, 
                //         rl.RAYWHITE
                // )
                scaling_factor := f32(0.34) // cityassets scaling factor
                rl.DrawModelEx(
                        models[map_data.tile_id[i]],
                        pos_model, 
                        rl.Vector3{ 0.0, 1.0, 0.0 }, 
                        map_data.tile_rotation_city[i],
                        rl.Vector3{ scaling_factor, scaling_factor, scaling_factor }, 
                        rl.RAYWHITE
                )
            }
            if spawn_car{
                car_pos := rl.Vector3{f32( grid[0].i + CELL_WIDTH/2), 0.3, f32(grid[0].j + CELL_WIDTH/2) }
                scaling_factor := f32(0.34)
                // scaling_factor := f32(CELL_WIDTH / GRID_SIZE) // citybits scaling factor
                rl.DrawModelEx(
                    car, 
                    car_pos,
                    rl.Vector3{ 0.0, 1.0, 0.0 }, 
                    0,
                    rl.Vector3{ scaling_factor, scaling_factor, scaling_factor }, 
                    rl.RAYWHITE)
            }
        }

        rl.DrawGrid(10, CELL_WIDTH)
        rl.DrawLine3D(rl.Vector3{ 0.0, 0.01, -10.0 }, rl.Vector3{ 0.0, 0.01, 10.0 }, rl.DARKBLUE )
        rl.DrawLine3D(rl.Vector3{ -10.0, 0.01, 0.0 }, rl.Vector3{ 10.0, 0.01, 0.0 }, rl.DARKBLUE )
        rl.EndMode3D()

        imgui.Render()
		rlimgui.render_draw_data(imgui.GetDrawData())

        rl.EndDrawing()
    }
    // unload models here
    for i in 0..<len(models){
        defer rl.UnloadModel(models[i])
    }
}