package threeDgrid

import "core:os"
import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:math"
import "core:math/rand"
import "core:slice"
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
    tile_path: []cstring,
    tile_name: []cstring,
    tile_id: []i32,
    texture: cstring,
    car: cstring
}

read_input_data :: proc(filepath: string, $T: typeid) -> T {
    file_data, ok := os.read_entire_file(filepath, context.allocator)
    if ok != nil {
        fmt.eprintln("Failed to read file.")
        return T{}
	}

	data: T
	err := json.unmarshal(file_data, &data)
	if err != nil {
		fmt.eprintln("Parsing error:", err)
        return T{}
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
    width: i32, // width of the tile ; this is not pixel
    height: i32, // height of the tile ; this is not pixel
    model_id: i32,
    scale_factor: f32
}

load_model :: proc(input_data: Tile_Input_Data, data: ^[]rl.Model) {
    texture := rl.LoadTexture(input_data.texture)
    rl.GenTextureMipmaps(&texture)
    rl.SetTextureFilter(texture, .TRILINEAR)

    if texture.id == 0 {
        fmt.println("Failed to load replacement texture")
        return
    }

    for item, i in input_data.tile_path{
        fmt.printfln("loading %v at position %v", item, i)
        data[i] = rl.LoadModel(item)
        fmt.printfln("number of materials: %v", data[i].materialCount)
        for j in 0..<data[i].materialCount {
            data[i].materials[j].maps[rl.MaterialMapIndex.ALBEDO].texture = texture
        }
    }
}

Car :: struct {
    model: rl.Model,
    scaling_factor: f32
}

load_car :: proc(input_data: Tile_Input_Data) -> Car {
     texture := rl.LoadTexture(input_data.texture)
    rl.GenTextureMipmaps(&texture)
    rl.SetTextureFilter(texture, .TRILINEAR)

    car: Car
    car.model = rl.LoadModel(input_data.car)
    for j in 0..<car.model.materialCount {
        car.model.materials[j].maps[rl.MaterialMapIndex.ALBEDO].texture = texture
    }
    car.scaling_factor = f32(1.0 / 3.0)
    
    return car
}

make_map :: proc(grid: ^[GRID_NUM_CELLS]Tile) {
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
            rng := rand.int32_range(0, 100)
            model_id: i32 
            if rng < 10{
                model_id = 0 // water
            } else if rng < 20 {
                model_id = 1 // sand
            } else{
                model_id = 2
            }
            tile := Tile{
                id = counter,
                id_row = i32(jj),
                id_col = i32(ii),
                i = i32(-CELL_WIDTH * GRID_SIZE + ii*CELL_WIDTH),
                j = i32(-CELL_WIDTH * GRID_SIZE + jj*CELL_WIDTH),
                status = false,//false if model_id == 0 else true,
                width = i32(CELL_WIDTH),
                height = i32(CELL_WIDTH),
                model_id = model_id,
                scale_factor = f32(1.0/3.0)
            }
            grid[counter] = tile
            counter += 1
        }        
    }
}

draw_map :: proc(grid: ^[GRID_NUM_CELLS]Tile, models: ^[]rl.Model, custom_shader: rl.Shader, highlighted_model: rl.Model) {
    for i in 0..<len(grid) {
        pos_model := rl.Vector3{f32( grid[i].i + CELL_WIDTH/2), 0.1, f32(grid[i].j + CELL_WIDTH/2) }
        pos := rl.Vector3{f32( grid[i].i + CELL_WIDTH/2), -0.01, f32(grid[i].j + CELL_WIDTH/2) }
        rl.DrawModelEx(
            models[grid[i].model_id],
            pos_model, 
            rl.Vector3{ 0.0, 1.0, 0.0 }, 
            0.0,
            rl.Vector3{ grid[i].scale_factor, grid[i].scale_factor, grid[i].scale_factor }, 
            rl.RAYWHITE
        )
        if grid[i].status == true {
            tmp_pos := rl.Vector3{f32( grid[i].i + CELL_WIDTH/2), 0.1, f32(grid[i].j + CELL_WIDTH/2) }
            rl.DrawModelEx(
                highlighted_model,
                tmp_pos, 
                rl.Vector3{ 0.0, 1.0, 0.0 }, 
                0.0,
                rl.Vector3{ 1.0, 1.0, 1.0 }, 
                rl.Color{255, 255, 0, 100}
            )
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
    // raylib initialization
    rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "3D model")
    rl.SetTargetFPS(TARGET_FPS)
    defer rl.CloseWindow()

    // imgui initialization
    imgui.CreateContext(nil)
	defer imgui.DestroyContext(nil)

    // Initialize ImGui Backend
    rlimgui.init()
    defer rlimgui.shutdown()

    // read input data
    map_data := read_input_data("map.json", Tile_Input_Data)
    fmt.printfln("map data: %v", map_data)

    // add render models
    max_models := i32(len(map_data.tile_name))
    models := make([]rl.Model, max_models)
    defer delete(models)
    load_model(map_data, &models)

    texture := rl.LoadTexture("assets/city_assets/texture/colorpaletteupdated.png")
    defer rl.UnloadTexture(texture)
    rl.GenTextureMipmaps(&texture)
    rl.SetTextureFilter(texture, .TRILINEAR)

    if texture.id == 0 {
        fmt.println("Failed to load replacement texture")
    }

    // camera
    camera := rl.Camera3D{
        position   = { 0.0, 20.0, 20.0 },
        target     = { 0.0, 0.0, 0.0 },
        up         = { 0.0, 1.0, 0.0 },
        fovy       = 60.0,
        projection = .PERSPECTIVE,
    }

    grid: [GRID_NUM_CELLS]Tile
    make_map(&grid)

    car := load_car(map_data)
    defer rl.UnloadModel(car.model)

    // highlighted tile
    base_model := rl.LoadModelFromMesh(rl.GenMeshCube(CELL_WIDTH, 0.01, CELL_WIDTH))
    defer rl.UnloadModel(base_model)

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
    custom_shader := rl.LoadShader(nil, "shaders/highlight.fs")
    defer rl.UnloadShader(custom_shader)

    // 3. Look up the uniform location for our tint vector
    col_mod_loc := rl.GetShaderLocation(custom_shader, "colMod")

    // 4. Map raylib's internal texture sampler location to our GLSL "albedoMap" uniform
    custom_shader.locs[rl.ShaderLocationIndex.MAP_ALBEDO] = rl.GetShaderLocation(custom_shader, "albedoMap")

    // 5. Send data to the shader uniform
    // A target tint color (e.g., Red: 1.0, Green: 0.3, Blue: 0.3, Alpha: 1.0)
    tint_color := rl.Vector4{1.0, 0.3, 0.3, 1.0}
    rl.SetShaderValue(custom_shader, col_mod_loc, &tint_color, rl.ShaderUniformDataType.VEC4)

    // car
    for i in 0..<car.model.materialCount{
        car.model.materials[i].shader = shader
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

    // texture for UI icons - testing
    road_straight_texture := rl.LoadTexture("assets/textures/road_straight_from_blender.png")
    defer rl.UnloadTexture(road_straight_texture)
    road_L_texture := rl.LoadTexture("assets/textures/road_L.png")
    defer rl.UnloadTexture(road_L_texture)
    grass_texture := rl.LoadTexture("assets/textures/grass_from_blender.png")
    defer rl.UnloadTexture(grass_texture)
    sand_texture := rl.LoadTexture("assets/textures/sand.png")
    defer rl.UnloadTexture(sand_texture)
    water_texture := rl.LoadTexture("assets/textures/water.png")
    defer rl.UnloadTexture(water_texture)

    // Main game loop
    for !rl.WindowShouldClose() {
        // update 
        dt := rl.GetFrameTime()
        update_camera(&camera, dt)

        // logic
        mouse_pos := rl.GetMousePosition()
        ray := rl.GetScreenToWorldRay(mouse_pos, camera)
        groundY := f32(0.0)
// 
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
                    grid[i].status = true
                    if rl.IsMouseButtonPressed(.LEFT) {
                        // grid[i].status = true
                        fmt.printfln("mouse click at %v", rl.Vector2{f32(gridX), f32(gridZ)})
                    }
                } else{
                    grid[i].status = false
                }
            }
        }

        if rl.IsKeyPressed(.ENTER){
            spawn_car = !spawn_car
        }

        // call imgui
        imgui_display(mouse_pos, gridX, gridZ, &light_direction, &light_color, &ambient_color)
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
        draw_map(&grid, &models, custom_shader, base_model)
        
        if spawn_car{
            car_pos := rl.Vector3{f32( grid[0].i + CELL_WIDTH/2), 0.3, f32(grid[0].j + CELL_WIDTH/2) }
            rl.DrawModelEx(
                car.model, 
                car_pos,
                rl.Vector3{ 0.0, 1.0, 0.0 }, 
                0,
                rl.Vector3{ car.scaling_factor, car.scaling_factor, car.scaling_factor }, 
                rl.RAYWHITE)
        }

        rl.DrawGrid(10, CELL_WIDTH)
        rl.DrawLine3D(rl.Vector3{ 0.0, 0.01, -10.0 }, rl.Vector3{ 0.0, 0.01, 10.0 }, rl.DARKBLUE )
        rl.DrawLine3D(rl.Vector3{ -10.0, 0.01, 0.0 }, rl.Vector3{ 10.0, 0.01, 0.0 }, rl.DARKBLUE )
        rl.EndMode3D()

        imgui.Render()
		rlimgui.render_draw_data(imgui.GetDrawData())

        // draw UI icons OUTSIDE mode3D
        rl.DrawTextureEx(road_straight_texture, rl.Vector2{10, 10}, 0.0, 0.05, rl.RAYWHITE)
        rl.DrawTextureEx(road_L_texture, rl.Vector2{80, 10}, 0.0, 0.05, rl.RAYWHITE)
        rl.DrawTextureEx(grass_texture, rl.Vector2{150, 10}, 0.0, 0.05, rl.RAYWHITE)
        rl.DrawTextureEx(sand_texture, rl.Vector2{220, 10}, 0.0, 0.05, rl.RAYWHITE)
        rl.DrawTextureEx(water_texture, rl.Vector2{290, 10}, 0.0, 0.05, rl.RAYWHITE)

        rl.EndDrawing()
    }
    // unload models here
    for i in 0..<len(models){
        defer rl.UnloadModel(models[i])
    }
}