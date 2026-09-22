## Docs

- just running this command ; pretty cool

```bash
odin doc .
```

```odin
package threeDgrid
        constants
                CELL_WIDTH :: 8
                        5 means a grid of 10 x 10, ie 5 on the positive X, 5 on the negative  ; same for Z

                GRID_NUM_CELLS :: 16
                GRID_SIZE :: 2
                SCREEN_HEIGHT :: 800
                SCREEN_WIDTH :: 800
                TARGET_FPS :: 60

        procedures
                clamp_f32 :: proc(v, min_value, max_value: f32) -> f32 {...} /* 35!147 */
                cross3 :: proc(a, b: rl.Vector3) -> rl.Vector3 {...} /* 35!583 */
                generate_grid :: proc(grid: ^[GRID_NUM_CELLS]Tile) {...} /* 34!1670 */
                        create a grid

                imgui_display :: proc(mouse_pos: rl.Vector2, gridX: i32, gridZ: i32) {...} /* 36!243 */
                length3 :: proc(v: rl.Vector3) -> f32 {...} /* 35!326 */
                main :: proc() {...} /* 34!3377 */
                normalize3 :: proc(v: rl.Vector3) -> rl.Vector3 {...} /* 35!428 */
                read_input_data :: proc(filepath: string) -> Tile_Input_Data {...} /* 34!709 */
                show_memory :: proc() {...} /* 34!2899 */
                update_camera :: proc(camera: ^rl.Camera3D, dt: f32) {...} /* 35!754 */

        types
                Tile :: struct {id: i32, id_row: i32, id_col: i32, i: i32, j: i32, status: bool, color: rl.Color, color_hit: rl.Color, width: i32, height: i32}
                Tile_Input_Data :: struct {tile_id: []i32, tile_rotation: []f32, tile_name: []string}


        fullpath:
                /Users/jonathanbouchet/WORK/ODIN_REPO_PROJECTS/odin-projects/3d_grid
        files:
                camera.odin
                imgui_panel.odin
                main.odin
```