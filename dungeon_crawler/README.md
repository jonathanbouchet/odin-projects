## main idea
- 1st person dungeon crawler
- idea is to define a map / level as a grid of 10x10 (currently) and place textures on each of the tiles:
    - initial test was to _hardcode_ the location of the tiles given that each texture is mapped to a CubeMesh of size (1,0.001, 1), in the case of XZ plane
    ```odin
    for j in 0..<TILE_Y{
            for i in 0..<TILE_X {
                x = -4.5 + f32(i*1.0)
                y = 0.5 + f32(j*1.0)
                z = -5.0
                rl.DrawModelEx(wall, rl.Vector3{x, y, z}, rl.Vector3{1, 0, 0}, 0.0, 1.0, rl.RAYWHITE)
            }
        }
    ```
    - the second test (currently coded) is to make a map by hand and place each tile in an [10x10] array for each direction (`LEFT`, `RIGHT` or `BACK` walls):
    ```bash
     {
            "data":[
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0
            ],
            "direction":"left"
        },
    ```
    - the final version should be a map generated from `Tiled`
## Assets
- each texture is a `32x32` pixels

## Docs
```bash
package main
        constants
                BACKGROUND :: rl.Color{0, 0, 28, 255}
                BACKGROUND_BLACK :: rl.Color{20, 20, 20, 255}
                BACKGROUND_UI :: rl.Color{251, 185, 84, 255}
                FPS :: 60
                GREEN :: rl.Color{57, 255, 20, 255}
                HEIGHT :: 400
                HEIGHT_FULL :: 400
                OUTLINE_UI :: rl.Color{122, 48, 69, 255}
                TILE_X :: 10
                TILE_Y :: 2
                TILE_Z :: 10
                WIDTH :: 640
                WIDTH_FULL :: 800
                WIDTH_UI :: 160

        procedures
                bool_to_32 :: proc(value: bool) -> f32 {...} /* main:player.odin!256 */
                button_rect :: proc(b: Button) -> rl.Rectangle {...} /* main:ui.odin!263 */
                clamp_f32 :: proc(v, min_value, max_value: f32) -> f32 {...} /* main:player.odin!73 */
                draw_button :: proc(b: Button) {...} /* main:ui.odin!669 */
                draw_debug :: proc() {...} /* main:main.odin!441 */
                draw_flames :: proc(fl: ^Flame_Animation) {...} /* main:props.odin!1045 */
                draw_floor_layer_from_map :: proc(texture_layer: Texture_Layer, model: rl.Model) {...} /* main:map.odin!2364 */
                draw_ui_panels :: proc(ui_rect: rl.Rectangle, hearts: [3]rl.Texture) {...} /* main:ui.odin!930 */
                draw_wall_layer_from_map :: proc(texture_layer: Texture_Layer, model: rl.Model, dir: Direction) {...} /* main:map.odin!337 */
                extract_all_layers :: proc(map_data: Map_Data) -> map[string]^Texture_Layer {...} /* main:input.odin!1926 */
                extract_layer_data :: proc(data: Map_Data, layer_id: i32) -> ^Texture_Layer {...} /* main:input.odin!1572 */
                f32_to_bool :: proc(value: f32) -> bool {...} /* main:player.odin!373 */
                load_flames :: proc() -> [4]rl.Model {...} /* main:props.odin!432 */
                main :: proc() {...} /* main:main.odin!739 */
                read_data :: proc(filepath: string, $T: typeid) -> T {...} /* main:input.odin!377 */
                read_input_data :: proc(filepath: string, $T: typeid) -> T {...} /* main:input.odin!902 */
                update_button :: proc(b: ^Button) {...} /* main:ui.odin!414 */
                update_player :: proc(player: ^Player, camera: ^rl.Camera3D) {...} /* main:player.odin!631 */

        types
                Button :: struct {position: rl.Vector2, texture: rl.Texture, base_color: rl.Color, switched_color: rl.Color, rotation: f32, scale: f32, state_changed: bool}
                Direction :: enum {LEFT, RIGHT, BACK, FRONT}
                Flame_Animation :: struct {frames: [4]rl.Model, position: rl.Vector3, animation_frame_length: f32, animation_current_frame: i32, run_frame_timer: f32}
                Map_Data :: struct {layers: [dynamic]Texture_Layer, tileheight: i32, tilewidth: i32, width: i32, height: i32}
                Player :: struct {position: rl.Vector3, speed: f32, eyes: f32, yaw: f32, pitch: f32, sensitivity: f32}
                Texture_Layer :: struct {id: i32, data: [TILE_X * TILE_Z]i32, height: i32, width: i32, name: string}


        fullpath:
                /Users/jonathanbouchet/WORK/ODIN_REPO_PROJECTS/odin-projects/dungeon_crawler
        files:
                input.odin
                main.odin
                map.odin
                player.odin
                props.odin
                ui.odin
```

