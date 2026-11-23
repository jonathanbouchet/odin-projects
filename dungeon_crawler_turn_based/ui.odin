package main

import "core:fmt"
import rl "vendor:raylib"

BUTTON_STATE :: enum{
	ACTIVE,
	PRESSED,
}

Button :: struct {
    position: rl.Vector2,
    textures: [2]rl.Texture2D,
    rotation: f32,
    scale: f32,
    state_changed: bool,
	state: BUTTON_STATE,
}

button_rect :: proc(b: Button) -> rl.Rectangle {
    /* 
    - return the Rectangle associated to that button
    - used for check if mouse has clicked the button
    */
    return rl.Rectangle{b.position.x, b.position.y, f32(b.textures[0].width), f32(b.textures[0].height)}
}

update_button :: proc(b: ^Button) {
    // update mouse state if clicked
    if rl.CheckCollisionPointRec(rl.GetMousePosition(), button_rect(b^)) && rl.IsMouseButtonPressed(.LEFT) {
        b.state_changed = !b.state_changed
		if b.state == .ACTIVE{
			b.state = .PRESSED
		} else {
			b.state = .ACTIVE
		}
        fmt.printfln("current state: %v", b.state_changed)
    }
}

draw_button :: proc(b: Button) {
    current_texture: rl.Texture
    if b.state_changed {
        current_texture = b.textures[1]
    } else {
        current_texture = b.textures[0]
    }
    rl.DrawTextureEx(current_texture, b.position, b.rotation, b.scale, rl.RAYWHITE)
}
