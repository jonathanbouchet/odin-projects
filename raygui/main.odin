package raygui_test

import "core:fmt"
import rl "vendor:raylib"
import "core:strconv"

Player :: struct {
    pos:        rl.Vector2,
    speed:      f32,
    color:      rl.Color,
    is_active:  bool,
    health:     i32,
}

draw_debug_overlay :: proc(p: ^Player) {
    // Draw a translucent panel container for the overlay
    panel_bounds := rl.Rectangle{550, 20, 230, 320}
    rl.DrawRectangleRec(panel_bounds, rl.Fade(rl.LIGHTGRAY, 0.85))
    rl.DrawRectangleLinesEx(panel_bounds, 1, rl.GRAY)

    // Title 
    rl.DrawText("DEBUG MENU", 560, 30, 16, rl.BLACK)

    // Raygui Checkbox to toggle boolean state
    rl.GuiCheckBox(rl.Rectangle{560, 60, 20, 20}, "Player Active", &p.is_active)

    // Raygui Slider to adjust float values (Speed)
    rl.DrawText("Speed:", 560, 95, 12, rl.DARKGRAY)
    rl.GuiSlider(
        rl.Rectangle{560, 110, 140, 20}, 
        nil, 
        nil, 
        &p.speed, 
        50.0, 
        500.0,
    )
    // Display value text next to slider
    speed_buf: [16]u8
    speed_str := strconv.write_float(speed_buf[:], f64(p.speed), 'f', 1, 32)
    rl.DrawText(cstring(raw_data(speed_str)), 710, 112, 12, rl.BLACK)

    // Raygui ValueBox to alter integers (Health)
    rl.DrawText("Health:", 560, 145, 12, rl.DARKGRAY)
    health_edit_mode := false // Keeps it static or togglable 
    rl.GuiValueBox(
        rl.Rectangle{560, 160, 100, 25}, 
        nil, 
        &p.health, 
        0, 
        100, 
        health_edit_mode,
    )

    // Raygui Color Bar / Pickers (or simple Toggles to mutate engine colors)
    rl.DrawText("Quick Colors:", 560, 205, 12, rl.DARKGRAY)
    if rl.GuiButton(rl.Rectangle{560, 220, 50, 25}, "Blue")  do p.color = rl.BLUE
    if rl.GuiButton(rl.Rectangle{615, 220, 50, 25}, "Red")   do p.color = rl.RED
    if rl.GuiButton(rl.Rectangle{670, 220, 50, 25}, "Green") do p.color = rl.GREEN

    // Display raw Read-Only metrics 
    pos_text := fmt.tprintf("X: %.1f\nY: %.1f", p.pos.x, p.pos.y)
    rl.DrawText(fmt.ctprintf("Position:\n%s", pos_text), 560, 260, 12, rl.DARKGRAY)

}

main :: proc(){
    rl.InitWindow(800, 600, "Odin + Raygui Debugger Example")
    defer rl.CloseWindow()

    rl.SetTargetFPS(60)

    // Initializing our state
    player := Player {
        pos       = {400, 300},
        speed     = 400.0,
        color     = rl.BLUE,
        is_active = true,
        health    = 80,
    }

    // Toggle for the UI overlay itself
    show_debug_menu := true

    for !rl.WindowShouldClose(){
        // logic
        dt := rl.GetFrameTime()
        // Toggle debug overlay with SPACE
        if rl.IsKeyPressed(.SPACE) {
            show_debug_menu = !show_debug_menu
        }

        // update
        if player.is_active {
            if rl.IsKeyDown(.LEFT)  || rl.IsKeyDown(.A) do player.pos.x -= player.speed * dt
            if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) do player.pos.x += player.speed * dt
            if rl.IsKeyDown(.UP)    || rl.IsKeyDown(.W) do player.pos.y -= player.speed * dt
            if rl.IsKeyDown(.DOWN)  || rl.IsKeyDown(.S) do player.pos.y += player.speed * dt
        }

        // rendering
        rl.BeginDrawing()
        rl.ClearBackground(rl.RAYWHITE)
        if player.is_active {
            rl.DrawCircleV(player.pos, 25, player.color)
        }
        if show_debug_menu {
            draw_debug_overlay(&player)
        }
        rl.EndDrawing()
    }
}