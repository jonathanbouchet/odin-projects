package main

import rl "vendor:raylib"

Dungeon_Map :: struct {
    data: [8][8]int, // dungron map as a 2d array of 0's and 1's: 1 = Wall, 0 = Floor
}

Game :: struct {
    maps: [2]Dungeon_Map, // game maps
    debug: bool, // flag to show fps, current level, screen mid-lines
    tile_debug: bool, // flag to show tile model cube wires
    current_map: Dungeon_Map, // current map used
    current_map_id: int, // index of the current map used
    view: rl.RenderTexture2D, // 'playable' view dimension with respect the all game window
    ui_container: rl.Rectangle, // dimnesion of the UI view
    player: Player, // player
    models: map[string]rl.Model, // models used by tiles,
    shader: rl.Shader,
    lighting: Lighting,
}