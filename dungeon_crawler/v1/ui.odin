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

draw_ui_panels :: proc(ui_rect: rl.Rectangle, hearts: [3]rl.Texture) {
    // ui_rect := rl.Rectangle{600,0, 200, 600}
    rl.DrawRectangleLinesEx(ui_rect, 4, OUTLINE_UI)
    for i: i32 = 0; i< len(hearts); i+=1{
        // rl.DrawTextureV(hearts[i], rl.Vector2{f32(600) + f32(i)*f32(hearts[i].width), 0}, rl.RAYWHITE)
        rl.DrawTextureEx(hearts[i], rl.Vector2{f32(700) + f32(i)*f32(hearts[i].width/2.0), 0}, 0.0, 0.5, rl.RAYWHITE)
    }
}