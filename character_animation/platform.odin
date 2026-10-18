package main

import rl "vendor:raylib"

Platform :: struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
    color: rl.Color
}

get_platform_rect :: proc(p: Platform) -> rl.Rectangle {
    return rl.Rectangle{f32(p.x), f32(p.y), f32(p.width), f32(p.height)}
}

draw_platform_lines :: proc(p: Platform) {
    // draw a platform outline
    rl.DrawRectangleLines(p.x, p.y, p.width, p.height, p.color)
}

draw_platform_full :: proc(p: Platform) {
    // draw a filled platform 
    rl.DrawRectangle(p.x, p.y, p.width, p.height, p.color)
}

draw_platforms_lines :: proc(p: [dynamic]Platform) {
    // draw a list of platforms outlines
    for platform in p{
        draw_platform_lines(platform)
    }
}