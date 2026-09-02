## about
- a breakout game inspired by Karl Zylinski's tutorial: https://www.youtube.com/watch?v=vfgZOEvO0kM&t=39s
- with some modifications along as i'm learning Odin, especially about how to organize code into `struct` and `proc`

## Random Dev Notes

- there is a trick in how the window and screen size are defined:
    - the window size is 640 x 640, with PADDLE_POS_Y :: 260
        - this means the paddle should show up above the mid-height
    - however a camera is apply with a zoom : `zoom = f32(rl.GetScreenHeight()) / SCREEN_SIZE`, where `SCREEN_SIZE` = 320
    - this means only the top left portion of the original 640x640 are displayed
    this also explains why, when drawing the debug mid-screens lines, a `zoom` factor is applied:
```odin
draw_debug :: proc(zoom: f32) {
    rl.DrawFPS(0, 0)
    rl.DrawLineV(rl.Vector2{0, HEIGTH/(2*zoom)}, {WIDTH, HEIGTH/(2*zoom)}, rl.Color{57, 255, 20, 255})
    rl.DrawLineV(rl.Vector2{WIDTH/(2 * zoom), 0}, {WIDTH/2/zoom, HEIGTH}, rl.Color{57, 255, 20, 255})
}
```

- by adding `package breakout` in all Odin files, there's no need to `import` the file in `main` (`main.odin` remaining the entry point)
    - for example, in`paddle.odin`: the x-position is clamped to the screenwidht, however, `SCREEN_WIDTH` is defined in `main.odin`

```odin
paddle.position.x = clamp(paddle.position.x, 0, SCREEN_SIZE - PADDLE_WIDTH)
``` 

- when a `proc` is using a structure in `read-only` mode, there's no need of pointer:
```odin
draw_paddle :: proc(paddle: Paddle, texture: rl.Texture2D) {
    rl.DrawTexturePro(
        texture,
        source_rect,
        rl.Rectangle{
            paddle.position.x,
            paddle.position.y,
            paddle.size.x,
            paddle.size.y,
        },
        {0, 0},
        0,
        rl.WHITE,
    )
}
```
but when you modify a structure, a pointer should be used:
```odin
update_paddle :: proc(paddle: ^Paddle) {
    if rl.IsKeyDown(.RIGHT) {
        paddle.position.x += paddle.speed
    }

    if rl.IsKeyDown(.LEFT) {
        paddle.position.x -= paddle.speed
    }
}
```
Inside a procedure receiving `^Paddle`, Odin automatically dereferences fields