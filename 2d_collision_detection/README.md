## references
- how to detect overlapping AABBs with a discrete method, the pitfalls
- Dylan Falconer YT: https://www.youtube.com/watch?v=nh37K1UMe_s&t=318s

## repo structure

```bash
package main
        constants
                BG :: rl.Color{0, 0, 0x1C, 0xFF}
                FADED :: rl.Color{0, 0xDF, 0, 0x44}
                FG :: rl.Color{0, 0xDF, 0, 0xFF}
                ITERATIONS :: 32
                MOVING_RECT_SIZE :: rl.Vector2{90, 140}
                SCREEN_CENTER :: rl.Vector2{WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2}
                WINDOW_HEIGHT :: 720
                WINDOW_WIDTH :: 1280

        procedures
                aabb_intersects_aabb :: proc(a, b: rl.Rectangle) -> bool {...} /* main:main.odin!2474 */
                get_overlap :: proc(a, b: rl.Rectangle) -> rl.Rectangle {...} /* main:main.odin!2783 */
                main :: proc() {...} /* main:main.odin!353 */
                rect_from_pos_size :: proc(pos, size: rl.Vector2) -> rl.Rectangle {...} /* main:main.odin!2347 */


        fullpath:
                /Users/jonathanbouchet/WORK/ODIN_REPO_PROJECTS/odin-projects/2d_collision_detection
        files:
                main.odin
```