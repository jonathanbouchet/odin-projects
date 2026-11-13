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

### Current status: 2026-11-01
- main change is how I convert the map made with `Tiled` to meshes in the game
- before each wall were a _flat_ `Model`, i.e.:
```bash
wall := rl.LoadModelFromMesh(rl.GenMeshCube(1.0, 1.0, 0.01)) // z-coordinate flat
``` 
- but it created some more complication to draw them because I had to disentangle `LEFT`, `RIGHT`, `BACK` walls
- not each wall is a full cube, meaning the `wall` texture is drawn on each face.
        - this is not an issue for the face on top because they are not seen

## Assets
- each texture is a `32x32` pixels

## Docs
```bash
package main
        constants
                BACKGROUND :: rl.Color{0, 0, 28, 255}
                BACKGROUND_BLACK :: rl.Color{20, 20, 20, 255}
                BACKGROUND_UI :: rl.Color{46, 34, 47, 255}
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
                bool_to_32 :: proc(value: bool) -> f32 {...} /* main:player.odin!282 */
                button_rect :: proc(b: Button) -> rl.Rectangle {...} /* main:ui.odin!263 */
                clamp_f32 :: proc(v, min_value, max_value: f32) -> f32 {...} /* main:player.odin!54 */
                draw_animation_model :: proc(am: ^Animation_To_Model, scale: f32) {...} /* main:props.odin!1486 */
                draw_button :: proc(b: Button) {...} /* main:ui.odin!669 */
                draw_debug :: proc(game: Game) {...} /* main:main.odin!461 */
                draw_doors_from_layer :: proc(texture_layer: Texture_Layer, model: rl.Model) {...} /* main:map.odin!2726 */
                draw_floor_layer_from_map :: proc(texture_layer: Texture_Layer, model: rl.Model) {...} /* main:map.odin!1212 */
                draw_full_wall_from_layer :: proc(texture_layer: Texture_Layer, model: rl.Model) {...} /* main:map.odin!1886 */
                draw_ui_panels :: proc(ui_rect: rl.Rectangle, hearts: [3]rl.Texture) {...} /* main:ui.odin!930 */
                extract_all_layers :: proc(map_data: Map_Data) -> map[string]^Texture_Layer {...} /* main:input.odin!1455 */
                extract_layer_data :: proc(data: Map_Data, layer_id: i32) -> ^Texture_Layer {...} /* main:input.odin!1101 */
                f32_to_bool :: proc(value: f32) -> bool {...} /* main:player.odin!429 */
                game_defer_delete :: proc(game: Game) {...} /* main:game.odin!14199 */
                game_draw :: proc(game: Game) {...} /* main:game.odin!3744 */
                game_draw_ui_container :: proc(game: Game) {...} /* main:game.odin!13916 */
                game_init :: proc() -> Game {...} /* main:game.odin!951 */
                game_load :: proc(game: ^Game) {...} /* main:game.odin!1231 */
                game_make_boundingboxes :: proc(game: ^Game) {...} /* main:game.odin!10209 */
                game_make_level_animations :: proc(game: ^Game, path: string, start_anim: i32, max_anim: i32, animation_frame_length: f32, layer: string) -> (: [dynamic]rl.Model, : [2]i32, : [2][dynamic]Animation_To_Model) {...} /* main:game.odin!11288 */
                game_switch_level :: proc(game: ^Game) {...} /* main:game.odin!8649 */
                game_update :: proc(game: ^Game) {...} /* main:game.odin!5144 */
                load_and_make_model :: proc(path: string, dim: rl.Vector3) -> rl.Model {...} /* main:input.odin!2583 */
                main :: proc() {...} /* main:main.odin!1618 */
                make_boundary_boxes :: proc(texture_layer: Texture_Layer, width: f32, height: f32, depth: f32, collider_type: string) -> [dynamic]rl.BoundingBox {...} /* main:map.odin!64 */
                make_model_from_animations :: proc(path: string, start_anim: i32, max_anim: i32, mesh_cube: [3]f32) -> [dynamic]rl.Model {...} /* main:props.odin!456 */
                player_bounding_box :: proc(player: Player) -> rl.BoundingBox {...} /* main:player.odin!812 */
                player_bounding_box_adjusted :: proc(player: Player) -> rl.BoundingBox {...} /* main:player.odin!1080 */
                read_input_data :: proc(filepath: string, $T: typeid) -> T {...} /* main:input.odin!431 */
                set_game :: proc() -> Settings {...} /* main:settings.odin!371 */
                update_button :: proc(b: ^Button) {...} /* main:ui.odin!414 */

        types
                Animation_To_Model :: struct {frames: [dynamic]rl.Model, position: rl.Vector3, animation_frame_length: f32, animation_current_frame: i32, run_frame_timer: f32}
                Button :: struct {position: rl.Vector2, texture: rl.Texture, base_color: rl.Color, switched_color: rl.Color, rotation: f32, scale: f32, state_changed: bool}
                Game :: struct {view_width: i32, view_height: i32, view: rl.RenderTexture2D, camera: rl.Camera3D, player: Player, map_data1: Map_Data, level1: map[string]^Texture_Layer, map_data2: Map_Data, level2: map[string]^Texture_Layer, wall: rl.Model, floor: rl.Model, door: rl.Model, walls_bb: [dynamic]rl.BoundingBox, doors_bb: [dynamic]rl.BoundingBox, coins_bb: [dynamic]rl.BoundingBox, debug: bool, current_level_id: i32, current_level: ^map[string]^Texture_Layer, flames: [dynamic]rl.Model, num_flames_arr: [2]i32, flame_animations_arr: [2][dynamic]Animation_To_Model, coins: [dynamic]rl.Model, num_coins_arr: [2]i32, coins_animations_arr: [2][dynamic]Animation_To_Model}
                Level :: struct {layers: map[string]^Texture_Layer}
                Map_Data :: struct {layers: [dynamic]Texture_Layer, tileheight: i32, tilewidth: i32, width: i32, height: i32}
                Player :: struct {position: rl.Vector3, velocity: rl.Vector3, speed: f32, eyes: f32, yaw: f32, pitch: f32, sensitivity: f32, is_colliding: bool, HP: i32, coins_collected: i32}
                Settings :: struct {WIDTH: i32, HEIGHT: i32, WIDTH_UI: i32, WIDTH_FULL: i32, HEIGHT_FULL: i32, FPS: i32, BACKGROUND: rl.Color, BACKGROUND_BLACK: rl.Color, BACKGROUND_UI: rl.Color, OUTLINE_UI: rl.Color, GREEN: rl.Color, TILE_X: i32, TILE_Z: i32, TILE_Y: i32}
                Texture_Layer :: struct {id: i32, data: [TILE_X * TILE_Z]i32, height: i32, width: i32, name: string}


        fullpath:
                /Users/jonathanbouchet/WORK/ODIN_REPO_PROJECTS/odin-projects/dungeon_crawler
        files:
                game.odin
                input.odin
                level.odin
                main.odin
                map.odin
                player.odin
                props.odin
                settings.odin
                ui.odin
```

