package main

import "core:mem"
import "core:fmt"
import "core:strings"
import "core:math"
import "core:math/rand"
import "core:math/linalg"
import rl "vendor:raylib"

TILE_SIZE :: 1.0
MAP_W :: 8
MAP_H :: 8
MOVE_SPEED :: 8.0 // Interpolation speed for movement
TURN_SPEED :: 8.0 // Interpolation speed for rotation
BACKGROUND :: rl.Color{20, 20, 20, 255}
BACKGROUND_UI :: rl.Color{46, 34, 47, 255}
OUTLINE_UI :: rl.Color{0, 0, 0, 100}
CROSSHAIR :: rl.Color{57, 255, 20, 255}
WIDTH :: 640
HEIGHT :: 400
WIDTH_UI :: 160
WIDTH_FULL :: 800
HEIGHT_FULL:: 400

load_and_make_model :: proc(path: string, dim: rl.Vector3) -> rl.Model {
    /*
    - load a static texture and aaply it to a Model
    */
    path_cstring := strings.clone_to_cstring(path)
    defer delete(path_cstring)
    texture := rl.LoadTexture(path_cstring) // 32x32 pixels minimalist
    model := rl.LoadModelFromMesh(rl.GenMeshCube(dim.x, dim.y, dim.z)) // full cube
    model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = texture
	return model
}

// 1 = Wall, 0 = Floor, 2 = Door

DUNGEON_MAP: Dungeon_Map = {
	[MAP_W][MAP_H]int {
		{1, 2, 1, 1, 1, 1, 1, 1},
		{1, 0, 0, 0, 1, 0, 0, 1},
		{1, 0, 1, 0, 1, 0, 1, 1},
		{1, 0, 1, 0, 0, 0, 0, 1},
		{1, 0, 1, 1, 1, 1, 0, 1},
		{1, 0, 0, 0, 0, 0, 0, 1},
		{1, 1, 1, 0, 1, 1, 1, 1},
		{1, 1, 1, 1, 1, 1, 1, 1},
	},
}
DUNGEON_MAP_2: Dungeon_Map = {
	[MAP_W][MAP_H]int {
		{1, 1, 1, 2, 1, 1, 1, 1},
		{1, 0, 0, 0, 0, 0, 0, 1},
		{1, 0, 0, 0, 0, 0, 1, 1},
		{1, 0, 0, 0, 0, 0, 1, 1},
		{1, 0, 0, 0, 0, 0, 0, 1},
		{1, 0, 0, 0, 0, 0, 0, 1},
		{1, 0, 0, 0, 0, 0, 0, 1},
		{1, 1, 1, 1, 1, 1, 1, 1},
	},
}

// Cardinal directions: 0 = North (-Z), 1 = East (+X), 2 = South (+Z), 3 = West (-X)
DIR_VECTORS := [4][2]int {
	{0, -1}, // North
	{1, 0}, // East
	{0, 1}, // South
	{-1, 0}, // West
}

is_walkable :: proc(game: Game, x, z: int) -> bool {
	if z < 0 || z >= len(game.current_map.data) || x < 0 || x >= len(game.current_map.data[0]) {
		return false
	}
	return game.current_map.data[z][x] == 0
}

grid_to_world :: proc(grid_pos: [2]int, y: f32) -> rl.Vector3 {
	return {f32(grid_pos.x) * TILE_SIZE, y, f32(grid_pos.y) * TILE_SIZE}
}

draw_debug :: proc(game: Game, b: Button) {
    /*
    various "debug" utils:
    - draw the FPS number
    - draw lines, h and v, representing the mid-screen
    */
	button_str := strings.clone_to_cstring(fmt.tprintf("BUTTON: %v", b.state))
    defer delete(button_str)
	current_map_str := strings.clone_to_cstring(fmt.tprintf("MAP: %v", game.current_map_id))
    defer delete(current_map_str)
    rl.DrawFPS(0, 0)
	rl.DrawText(current_map_str, 0, 20, 20, CROSSHAIR)
	rl.DrawText(button_str, 0, 40, 20, CROSSHAIR)
    rl.DrawLineV(rl.Vector2{0, HEIGHT_FULL/2}, {WIDTH, HEIGHT_FULL/2}, CROSSHAIR)
    rl.DrawLineV(rl.Vector2{WIDTH/2, 0}, {WIDTH/2, HEIGHT}, CROSSHAIR)
}

main :: proc() {
	// entry point
    tracking: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking)

    defer {
        fmt.println("Memory statistics:")
        fmt.printfln("  Current:   %d bytes", tracking.current_memory_allocated)
        fmt.printfln("  Peak:      %d bytes", tracking.peak_memory_allocated)
        fmt.printfln("  Allocated: %d bytes total", tracking.total_memory_allocated)
        fmt.printfln("  Freed:     %d bytes total", tracking.total_memory_freed)
        fmt.printfln("  Allocations: %d", tracking.total_allocation_count)
        fmt.printfln("  Frees:       %d", tracking.total_free_count)

        if len(tracking.allocation_map) > 0 {
            fmt.eprintf("\nUnfreed allocations: %d\n", len(tracking.allocation_map))

            for _, entry in tracking.allocation_map {
                fmt.eprintf(
                    "  %d bytes allocated at %v\n",
                    entry.size,
                    entry.location,
                )
            }
        }

        if len(tracking.bad_free_array) > 0 {
            fmt.eprintf(
                "\nIncorrect frees: %d\n",
                len(tracking.bad_free_array),
            )

            for entry in tracking.bad_free_array {
                fmt.eprintf(
                    "  %p freed at %v\n",
                    entry.memory,
                    entry.location,
                )
            }
        }

        mem.tracking_allocator_destroy(&tracking)
    }

	rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT, .WINDOW_HIGHDPI})
	rl.InitWindow(WIDTH_FULL, HEIGHT_FULL, "dungeon crwaler")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	p := Player {
		grid_pos   = {1, 1},
		facing     = 1, // Facing East
		eye_height = TILE_SIZE / 2,
	}
	p.visual_pos = grid_to_world(p.grid_pos, p.eye_height)
	p.target_yaw = f32(p.facing) * (math.PI / 2.0)
	p.visual_yaw = p.target_yaw

	game:= Game{
		maps = [2]Dungeon_Map{DUNGEON_MAP, DUNGEON_MAP_2},
		debug = true,
		tile_debug = false,
		view = rl.LoadRenderTexture(i32(WIDTH), i32(HEIGHT)), // game window
		player = p,
	}
	game.current_map = game.maps[1]
	game.current_map_id = 1

	camera := rl.Camera3D {
		position   = game.player.visual_pos,
		up         = {0, 1, 0},
		fovy       = 60.0,
		projection = .PERSPECTIVE,
	}

	game.models["wall"] = load_and_make_model("assets/wall_64x64_door-1.png", rl.Vector3{TILE_SIZE, TILE_SIZE, TILE_SIZE})
	game.models["floor"] = load_and_make_model("assets/floor_64x64.png", rl.Vector3{TILE_SIZE, 0.01, TILE_SIZE})
	game.models["ceiling_1"] = load_and_make_model("assets/ceiling_64x64-1.png", rl.Vector3{TILE_SIZE, 0.01, TILE_SIZE})
	game.models["ceiling_2"] = load_and_make_model("assets/ceiling_64x64-2.png", rl.Vector3{TILE_SIZE, 0.01, TILE_SIZE})
	game.models["ceiling_3"] = load_and_make_model("assets/ceiling_64x64-3.png", rl.Vector3{TILE_SIZE, 0.01, TILE_SIZE})
	game.models["door"] = load_and_make_model("assets/wall_64x64_door-2.png", rl.Vector3{TILE_SIZE, TILE_SIZE, TILE_SIZE})

	button_texture := rl.LoadTexture("assets/Button_Blue.png")
	defer rl.UnloadTexture(button_texture)
	button_pressed_texture := rl.LoadTexture("assets/Button_Blue_Pressed.png")
	defer rl.UnloadTexture(button_pressed_texture)

	button := Button{
		position = rl.Vector2{WIDTH + 10, 20},
		textures = [2]rl.Texture2D{button_texture, button_pressed_texture},
		rotation = 0,
		scale = 1.0,
		state = .ACTIVE,
	}

	defer delete(game.models)
	defer rl.UnloadModel(game.models["wall"])
	defer rl.UnloadModel(game.models["floor"])
	defer rl.UnloadModel(game.models["ceiling_1"])
	defer rl.UnloadModel(game.models["ceiling_2"])
	defer rl.UnloadModel(game.models["ceiling_3"])
	defer rl.UnloadTexture(game.models["wall"].materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture)
	defer rl.UnloadTexture(game.models["floor"].materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture)
	defer rl.UnloadTexture(game.models["ceiling_1"].materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture)
	defer rl.UnloadTexture(game.models["ceiling_2"].materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture)
	defer rl.UnloadTexture(game.models["ceiling_3"].materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture)

	game.ui_container = rl.Rectangle{f32(WIDTH), 0, f32(WIDTH_UI), HEIGHT}

	// button

	// rng number before the level is drawn
	r32 := rand.float32() // f32 in [0, 1)

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		// 1. Handle Turn Input (90-degree increments)
		if rl.IsKeyPressed(.Q) || rl.IsKeyPressed(.LEFT) {
			game.player.facing = (game.player.facing + 3) % 4 // Wrap -1 to 3
			game.player.target_yaw -= math.PI / 2.0
		}
		if rl.IsKeyPressed(.E) || rl.IsKeyPressed(.RIGHT) {
			game.player.facing = (game.player.facing + 1) % 4
			game.player.target_yaw += math.PI / 2.0
		}

		// 2. Handle Grid Movement Input
		move_dir := [2]int{0, 0}
		fwd := DIR_VECTORS[game.player.facing]
		right := DIR_VECTORS[(game.player.facing + 1) % 4]

		if rl.IsKeyPressed(.W) || rl.IsKeyPressed(.UP) {
			move_dir = fwd
		} else if rl.IsKeyPressed(.S) || rl.IsKeyPressed(.DOWN) {
			move_dir = -fwd
		} else if rl.IsKeyPressed(.D) {
			move_dir = right
		} else if rl.IsKeyPressed(.A) {
			move_dir = -right
		}

		// Apply move if destination tile is clear
		if move_dir != {0, 0} {
			next_x := game.player.grid_pos.x + move_dir.x
			next_z := game.player.grid_pos.y + move_dir.y
			if is_walkable(game, next_x, next_z) {
				game.player.grid_pos = {next_x, next_z}
			}
		}

		// 3. Smoothly Interpolate Visuals to Match Logical Grid State
		target_world_pos := grid_to_world(game.player.grid_pos, game.player.eye_height)
		game.player.visual_pos = linalg.lerp(game.player.visual_pos, target_world_pos, 1.0 - math.exp(-MOVE_SPEED * dt))
		game.player.visual_yaw = math.lerp(game.player.visual_yaw, game.player.target_yaw, 1.0 - math.exp(-TURN_SPEED * dt))

		// 4. Update Raylib Camera3D
		// Facing 0 (North) corresponds to -Z, Facing 1 (East) to +X
		look_dir := rl.Vector3 {
			math.sin(game.player.visual_yaw),
			0,
			-math.cos(game.player.visual_yaw),
		}
		camera.position = game.player.visual_pos
		camera.target = game.player.visual_pos + look_dir

		// ui updates
		update_button(&button)

		// render game window
        rl.BeginTextureMode(game.view)
        rl.ClearBackground(BACKGROUND)

		rl.BeginMode3D(camera)
		for z in 0 ..< len(game.current_map.data) {
			for x in 0 ..< len(game.current_map.data[0]) {
				world_pos := grid_to_world({x, z}, 0)
				world_pos_ceiling := grid_to_world({x, z}, 1)
				if game.current_map.data[z][x] == 1 {
					wall_pos := rl.Vector3{world_pos.x, TILE_SIZE / 2.0, world_pos.z}
					rl.DrawModelEx(game.models["wall"], wall_pos, rl.Vector3{0, 1, 0}, 0.0, 1.0, rl.RAYWHITE)
					if game.tile_debug{
						rl.DrawCubeWires(wall_pos, TILE_SIZE, TILE_SIZE, TILE_SIZE, rl.RED)
					}
				} else if game.current_map.data[z][x] == 2 {
					door_pos := rl.Vector3{world_pos.x, TILE_SIZE / 2.0, world_pos.z}
					rl.DrawModelEx(game.models["door"], door_pos, rl.Vector3{0, 1, 0}, 0.0, 1.0, rl.RAYWHITE)
				} else {
					if r32 < 0.33{
						rl.DrawModelEx(game.models["ceiling_1"], world_pos_ceiling, rl.Vector3{1, 0, 0}, 0.0, 1.0, rl.RAYWHITE)
					} else if r32 < 0.66{
						rl.DrawModelEx(game.models["ceiling_2"], world_pos_ceiling, rl.Vector3{1, 0, 0}, 0.0, 1.0, rl.RAYWHITE)
					} else {
						rl.DrawModelEx(game.models["ceiling_3"], world_pos_ceiling, rl.Vector3{1, 0, 0}, 0.0, 1.0, rl.RAYWHITE)
					}
					rl.DrawModelEx(game.models["floor"], world_pos, rl.Vector3{1, 0, 0}, 0.0, 1.0, rl.RAYWHITE)
				}
			}
		}
		rl.EndMode3D()
		rl.EndTextureMode()

		// render UI
		rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND_UI)
		rl.DrawTextureRec(
            game.view.texture,
            rl.Rectangle{0, 0, f32(WIDTH), -f32(HEIGHT)},
            rl.Vector2{0, 0},
            rl.WHITE,
        )
		rl.DrawRectangleLinesEx(game.ui_container, 4, OUTLINE_UI)
		draw_button(button)
		if game.debug {
			draw_debug(game, button)
		}
		rl.EndDrawing()
	}
}
