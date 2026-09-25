## Docs

- just running this command ; pretty cool

```bash
odin doc .
```

```odin
package threeDgrid
        constants
                CELL_WIDTH :: 4
                        5 means a grid of 10 x 10, ie 5 on the positive X, 5 on the negative  ; same for Z

                GRID_NUM_CELLS :: 36
                GRID_SIZE :: 3
                SCREEN_HEIGHT :: 1000
                SCREEN_WIDTH :: 1000
                TARGET_FPS :: 60

        procedures
                clamp_f32 :: proc(v, min_value, max_value: f32) -> f32 {...} /* 35!147 */
                cross3 :: proc(a, b: rl.Vector3) -> rl.Vector3 {...} /* 35!583 */
                draw_map :: proc(grid: ^[GRID_NUM_CELLS]Tile, models: ^[]rl.Model) {...} /* 34!4003 */
                imgui_display :: proc(mouse_pos: rl.Vector2, gridX: i32, gridZ: i32, light_pos: ^[3]f32, light_color: ^[3]f32, ambient_color: ^[3]f32) {...} /* 36!203 */
                length3 :: proc(v: rl.Vector3) -> f32 {...} /* 35!326 */
                load_car :: proc(input_data: Tile_Input_Data) -> Car {...} /* 34!2332 */
                load_model :: proc(input_data: Tile_Input_Data, data: ^[]rl.Model) {...} /* 34!1609 */
                main :: proc() {...} /* 34!5061 */
                make_map :: proc(grid: ^[GRID_NUM_CELLS]Tile) {...} /* 34!2771 */
                normalize3 :: proc(v: rl.Vector3) -> rl.Vector3 {...} /* 35!428 */
                read_input_data :: proc(filepath: string, $T: typeid) -> T {...} /* 34!776 */
                show_memory :: proc() {...} /* 34!4583 */
                update_camera :: proc(camera: ^rl.Camera3D, dt: f32) {...} /* 35!754 */
                update_shader_values :: proc(light_direction: ^[3]f32, light_color: ^[3]f32, ambient_color: ^[3]f32, light_direction_loc: int, light_color_loc: int, ambient_color_loc: int, shader: rl.Shader) {...} /* 37!71 */

        types
                Car :: struct {model: rl.Model, scaling_factor: f32}
                Tile :: struct {id: i32, id_row: i32, id_col: i32, i: i32, j: i32, status: bool, width: i32, height: i32, model_id: i32, scale_factor: f32}
                Tile_Input_Data :: struct {tile_path: []cstring, tile_name: []cstring, tile_id: []i32, texture: cstring, car: cstring}


        fullpath:
                /Users/jonathanbouchet/WORK/ODIN_REPO_PROJECTS/odin-projects/3d_grid
        files:
                camera.odin
                imgui_panel.odin
                main.odin
                shaders.odin
```