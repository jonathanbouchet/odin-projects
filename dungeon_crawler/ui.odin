package main

import "core:fmt"
import rl "vendor:raylib"

Button :: struct {
    position: rl.Vector2,
    texture: rl.Texture,
    base_color: rl.Color,
    switched_color: rl.Color,
    rotation: f32,
    scale: f32,
    state_changed: bool,
}

button_rect :: proc(b: Button) -> rl.Rectangle {
    return rl.Rectangle{b.position.x, b.position.y, f32(b.texture.width), f32(b.texture.height)}
}

update_button :: proc(b: ^Button) {
    if rl.CheckCollisionPointRec(rl.GetMousePosition(), button_rect(b^)) && rl.IsMouseButtonPressed(.LEFT) {
        b.state_changed = ! b.state_changed
        fmt.printfln("current state: %v", b.state_changed)
    }
}

draw_button :: proc(b: Button) {
    current_col: rl.Color
    if b.state_changed {
        current_col = b.base_color
    } else {
        current_col = b.switched_color
    }
    rl.DrawTextureEx(b.texture, b.position, b.rotation, b.scale, current_col)
}