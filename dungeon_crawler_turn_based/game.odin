package main

import rl "vendor:raylib"

Dungeon_Map :: struct {
    data: [8][8]int,
}

Game :: struct {
    maps: [2]Dungeon_Map,
    debug: bool,
    current_map: Dungeon_Map,
    current_map_id: int,
    view: rl.RenderTexture2D,
    ui_container: rl.Rectangle,
    player: Player,
    models: map[string]rl.Model,
}