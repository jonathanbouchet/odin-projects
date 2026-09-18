## Docs

- just running this command ; pretty cool

```bash
odin doc .
```

```odin
package threeDgrid
        constants
                GRID_CELL :: 2
                GRID_SIZE :: 2
                SCREEN_HEIGHT :: 600
                SCREEN_WIDTH :: 600
                TARGET_FPS :: 60

        variables
                grid: [GRID_SIZE * GRID_SIZE]Tile 

        procedures
                clamp_f32 :: proc(v, min_value, max_value: f32) -> f32 {...} /* 35!147 */
                cross3 :: proc(a, b: rl.Vector3) -> rl.Vector3 {...} /* 35!583 */
                generate_grid :: proc() {...} /* 34!573 */
                        create a grid

                imgui_display :: proc() {...} /* 36!243 */
                length3 :: proc(v: rl.Vector3) -> f32 {...} /* 35!326 */
                main :: proc() {...} /* 34!2166 */
                normalize3 :: proc(v: rl.Vector3) -> rl.Vector3 {...} /* 35!428 */
                show_memory :: proc() {...} /* 34!1688 */
                update_camera :: proc(camera: ^rl.Camera3D, dt: f32) {...} /* 35!754 */

        types
                Tile :: struct {i: i32, j: i32, x: f32, y: f32, z: f32, status: bool, color: rl.Color, width: i32, height: i32, bb: rl.BoundingBox}


        fullpath:
                /Users/jonathanbouchet/WORK/ODIN_REPO_PROJECTS/odin-projects/3d_grid
        files:
                camera.odin
                imgui_panel.odin
                main.odin
```