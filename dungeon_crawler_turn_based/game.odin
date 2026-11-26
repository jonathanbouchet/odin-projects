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
}