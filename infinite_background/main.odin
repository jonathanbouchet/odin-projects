package main

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

WIDTH :: 768
HEIGHT :: 432

Animated_Texture :: struct {
    texture: rl.Texture,
    position: [2]f32,
    offset: f32,
    speed: i32
}

update_animated_texture :: proc (anim_texture: ^Animated_Texture) {
    dt := rl.GetFrameTime()
    anim_texture.position.x -= f32(dt) * f32(anim_texture.speed)
    if (anim_texture.position.x + f32(anim_texture.texture.width)) < 0 {
        anim_texture.position.x = f32(anim_texture.offset)*f32(anim_texture.texture.width)
    }
}

draw_animated_texture :: proc (anim_texture: Animated_Texture) {
    rl.DrawTextureV(anim_texture.texture, anim_texture.position, rl.RAYWHITE)
}

main :: proc () {
    tracking: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking)

    defer {
        fmt.printfln(
            "Current memory: %d bytes, peak memory: %d bytes",
            tracking.current_memory_allocated,
            tracking.peak_memory_allocated,
        )

        if len(tracking.allocation_map) > 0 {
            fmt.eprintln("Unfreed allocations:")

            for _, entry in tracking.allocation_map {
                fmt.eprintf(
                    "- %d bytes @ %v\n",
                    entry.size,
                    entry.location,
                )
            }
        }

        mem.tracking_allocator_destroy(&tracking)
    }

    rl.InitWindow(WIDTH, HEIGHT, "parallax")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)
    background_fixed := rl.LoadTexture("assets/plx-1.png")
    background_animated_1 := rl.LoadTexture("assets/plx-2.png") // 768 width
    background_animated_2 := rl.LoadTexture("assets/plx-5.png") // 768 width
    background_animated_3 := rl.LoadTexture("assets/ground.png") // 320 width

    background_00 := Animated_Texture{
        texture = background_animated_1, 
        position = rl.Vector2{}, 
        offset = 1, 
        speed = 10
    }
    background_01 := Animated_Texture{
        texture = background_animated_1, 
        position = rl.Vector2{f32(background_animated_1.width), 0}, 
        offset = 1, 
        speed = 10
    }

    background_10 := Animated_Texture{
        texture = background_animated_2, 
        position = rl.Vector2{}, 
        offset = 1, 
        speed = 20
    }
    background_11 := Animated_Texture{
        texture = background_animated_2, 
        position = rl.Vector2{f32(background_animated_2.width), 0}, 
        offset = 1, 
        speed = 20
    }

    background_20 := Animated_Texture{
        texture = background_animated_3, 
        position = rl.Vector2{0, f32(HEIGHT - background_animated_3.height/2)}, 
        offset = 3, 
        speed = 50
    }
    background_21 := Animated_Texture{
        texture = background_animated_3, 
        position = rl.Vector2{f32(background_animated_3.width), f32(HEIGHT - background_animated_3.height/2)}, 
        offset = 3, 
        speed = 50
    }
    background_22 := Animated_Texture{
        texture = background_animated_3, 
        position = rl.Vector2{f32(2*background_animated_3.width), f32(HEIGHT - background_animated_3.height/2)}, 
        offset = 3, 
        speed = 50
    }
    background_23 := Animated_Texture{
        texture = background_animated_3, 
        position = rl.Vector2{f32(3*background_animated_3.width), f32(HEIGHT - background_animated_3.height/2)}, 
        offset = 3, 
        speed = 50
    }

    defer rl.UnloadTexture(background_fixed)
    defer rl.UnloadTexture(background_animated_1)
    defer rl.UnloadTexture(background_animated_2)
    defer rl.UnloadTexture(background_animated_3)

    for !rl.WindowShouldClose() {
        // update
        update_animated_texture(&background_00)
        update_animated_texture(&background_01)
        update_animated_texture(&background_10)
        update_animated_texture(&background_11)
        update_animated_texture(&background_20)
        update_animated_texture(&background_21)
        update_animated_texture(&background_22)
        update_animated_texture(&background_23)
     

        //rendering
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        rl.DrawTextureV(background_fixed, rl.Vector2{}, rl.RAYWHITE)
        draw_animated_texture(background_00)
        draw_animated_texture(background_01)
        draw_animated_texture(background_10)
        draw_animated_texture(background_11)
        draw_animated_texture(background_20)
        draw_animated_texture(background_21)
        draw_animated_texture(background_22)
        draw_animated_texture(background_23)
       
        rl.EndDrawing()
    }
}