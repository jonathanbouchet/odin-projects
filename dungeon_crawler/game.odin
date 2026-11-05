package main

import "vendor:raylib"

Game :: struct {
    player: Player,
    level1: Level,
    level2: Level,
}

game_init :: proc() -> Game{
    game: Game
    return game
}
draw_game :: proc(game: Game){

}