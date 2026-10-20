```bash
package main
        constants
                BACKGROUND :: rl.Color{15, 15, 15, 255}
                FPS :: 60
                GREEN :: rl.Color{57, 255, 20, 255}
                        BACKGROUND :: rl.Color{ 150, 190, 220, 255 }

                HEIGHT :: 600
                TILE_WIDTH :: 64
                        BACKGROUND :: rl.Color{0, 0, 28, 255}

                WIDTH :: 600

        variables
                gravity: f32 = 500

        procedures
                draw_debug :: proc(player: Player) {...} /* main:main.odin!789 */
                draw_platform :: proc(texture: rl.Texture, tile_id: i32) {...} /* main:main.odin!382 */
                draw_platform_full :: proc(p: Platform) {...} /* main:platform.odin!438 */
                draw_platform_lines :: proc(p: Platform) {...} /* main:platform.odin!298 */
                draw_platforms_lines :: proc(p: [dynamic]Platform) {...} /* main:platform.odin!575 */
                draw_player :: proc(player: Player, texture: rl.Texture) {...} /* main:player.odin!1170 */
                get_animation_string :: proc(anim: ANIMATION_NAME) -> string {...} /* main:player.odin!1359 */
                get_platform_rect :: proc(p: Platform) -> rl.Rectangle {...} /* main:platform.odin!163 */
                get_player_rect :: proc(player: Player) -> rl.Rectangle {...} /* main:player.odin!858 */
                load_textures_from_directory :: proc(directory: string) -> [dynamic]rl.Texture {...} /* main:animations.odin!293 */
                main :: proc() {...} /* main:main.odin!1674 */
                resolve_collision :: proc(player: ^Player, platforms: [dynamic]Platform, axis: Axis) {...} /* main:utils.odin!112 */
                switch_state :: proc(player: ^Player) {...} /* main:player.odin!1690 */
                unload_textures :: proc(textures: ^map[string][dynamic]rl.Texture) {...} /* main:animations.odin!1473 */
                update_animation :: proc(player: ^Player, textures: ^map[string][dynamic]rl.Texture) -> rl.Texture {...} /* main:player.odin!2053 */
                update_player :: proc(player: ^Player, platforms: [dynamic]Platform) {...} /* main:player.odin!3576 */

        types
                ANIMATION_NAME :: enum {ATTACK, IDLE, JUMP, RUN}
                Animation_Frames :: struct {name: ANIMATION_NAME, textures: [dynamic]rl.Texture}
                Axis :: enum {X, Y}
                Platform :: struct {x: i32, y: i32, width: i32, height: i32, color: rl.Color}
                Player :: struct {position: [2]f32, velocity: [2]f32, width: f32, height: f32, offset_x: i32, offset_y: i32, collider_width: f32, collider_height: f32, grounded: bool, was_grounded: bool, state: ANIMATION_NAME, previous_state: ANIMATION_NAME, animation_frame_length: f32, animation_current_frame: i32, run_frame_timer: f32}
                Player_Animations :: struct {animations: [8]Animation_Frames}


        fullpath:
                /Users/jonathanbouchet/WORK/ODIN_REPO_PROJECTS/odin-projects/character_animation
        files:
                animations.odin
                main.odin
                platform.odin
                player.odin
                utils.odin
```