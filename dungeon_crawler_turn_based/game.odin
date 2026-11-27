package main

import rl "vendor:raylib"

Dungeon_Data :: [MAP_W][MAP_H]int

Map_Data :: struct {
    data: [dynamic][MAP_W][MAP_H]int,
}

Game :: struct {
    maps: Map_Data, // game maps:  1 = Wall, 0 = Floor, 2 = Door
    debug: bool, // flag to show fps, current level, screen mid-lines
    tile_debug: bool, // flag to show tile model cube wires
    current_map: Dungeon_Data, // current map used
    current_map_id: int, // index of the current map used
    view: rl.RenderTexture2D, // 'playable' view dimension with respect the all game window
    ui_container: rl.Rectangle, // dimnesion of the UI view
    player: Player, // player
    models: map[string]rl.Model, // models used by tiles,
    shader: rl.Shader,
    lighting: Lighting,
    font: rl.Font,
    button: Button, //testing: it sould be an array of UI element in the future
}

draw_level :: proc(game: Game) {
    for z in 0 ..< len(game.current_map) {
        for x in 0 ..< len(game.current_map[0]) {
            world_pos := grid_to_world({x, z}, 0)
            world_pos_ceiling := grid_to_world({x, z}, 1)
            if game.current_map[z][x] == 1 {
                wall_pos := rl.Vector3{world_pos.x, TILE_SIZE / 2.0, world_pos.z}
                rl.DrawModelEx(game.models["wall"], wall_pos, rl.Vector3{0, 1, 0}, 0.0, 1.0, rl.RAYWHITE)
                if game.tile_debug{
                    rl.DrawCubeWires(wall_pos, TILE_SIZE, TILE_SIZE, TILE_SIZE, rl.RED)
                }
            } else if game.current_map[z][x] == 2 {
                door_pos := rl.Vector3{world_pos.x, TILE_SIZE / 2.0, world_pos.z}
                rl.DrawModelEx(game.models["door"], door_pos, rl.Vector3{0, 1, 0}, 0.0, 1.0, rl.RAYWHITE)
            } else {
                rl.DrawModelEx(game.models["ceiling_1"], world_pos_ceiling, rl.Vector3{1, 0, 0}, 0.0, 1.0, rl.RAYWHITE)
                rl.DrawModelEx(game.models["floor"], world_pos, rl.Vector3{1, 0, 0}, 0.0, 1.0, rl.RAYWHITE)
            }
        }
    }
}
