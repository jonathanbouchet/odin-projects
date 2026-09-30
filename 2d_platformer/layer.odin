package main

import "core:math"
import rl "vendor:raylib"

draw_background :: proc (texture: rl.Texture) {
    x := i32(0)
    y := i32(5)
    source_rect := rl.Rectangle{f32(x * TILE_WIDTH), f32(y * TILE_WIDTH), TILE_WIDTH, TILE_WIDTH }
    for i in 0..<NUM_TILE_X {
        for j in 0..<NUM_TILE_Y {
            // center of the screen
            dest_rect := rl.Rectangle{
                f32(i*TILE_WIDTH), 
                f32(j*TILE_WIDTH), 
                TILE_WIDTH, 
                TILE_WIDTH
            } 
            rl.DrawTexturePro(
                texture, 
                source_rect, 
                dest_rect, 
                rl.Vector2{0, 0}, 
                0.0, 
                rl.RAYWHITE
            )
        }
    }
}

draw_layer :: proc (texture: rl.Texture, layer: ^Texture_Layer, is_collision: bool) {
    x: f32
    y: f32
    i: f32
    j: f32
    tile_value: i32
    for tile_id in 0..<len(layer.data) {
        if layer.data[tile_id] > 0 {
            tile_value = layer.data[tile_id]
            y = math.floor_f32(f32(tile_value) / NUM_TILE_X)
            x = f32(tile_value - 1) - f32(y*NUM_TILE_X)
            source_rect := rl.Rectangle{f32(x * TILE_WIDTH), f32(y * TILE_WIDTH), TILE_WIDTH, TILE_WIDTH }

            j = math.floor_f32(f32(tile_id) / NUM_TILE_X)
            i = f32(tile_id % NUM_TILE_X)

            // fmt.printfln("tile_id: %v, tile_value: %v, x: %v, y: %v, i: %v, j: %v", tile_id, tile_value, x,y,i,j)

            dest_rect := rl.Rectangle{
                    f32(i*TILE_WIDTH), 
                    f32(j*TILE_WIDTH), 
                    TILE_WIDTH, 
                    TILE_WIDTH
                } 
            if is_collision {
                rl.DrawRectangleLines(i32(dest_rect.x), i32(dest_rect.y), TILE_WIDTH, TILE_WIDTH, rl.RED)
            } else {
                rl.DrawTexturePro(
                    texture, 
                    source_rect, 
                    dest_rect, 
                    rl.Vector2{0, 0}, 
                    0.0, 
                    rl.RAYWHITE
                )
            }
        }
    }
}
