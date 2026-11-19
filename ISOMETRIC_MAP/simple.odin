package isometric_map_simple

import "core:fmt"
import "core:strings"
import "core:mem"
import "core:math"
import rl "vendor:raylib"

SCREEN_WIDTH :: 640
SCREEN_HEIGHT :: 320
TILE_WIDTH :: 128
TILE_HEIGHT :: 64
GRID_SIZE :: 20
OFFSET_X :: SCREEN_WIDTH / 2
OFFSET_Y :: 50
FPS :: 60
BACKGROUND :: rl.Color{0, 0, 28, 255}
BACKGROUND_BLACK :: rl.Color{20, 20, 20, 255 } // light black
GREEN :: rl.Color{57, 255, 20, 255}

iso_to_screen :: proc(g_coord: [2]i32) -> [2]f32 {
    // Convert 2D grid coordinates to isometric screen coordinates
    return [2]f32{
        f32((g_coord[0] - g_coord[1]) * (TILE_WIDTH / 2) + OFFSET_X),
        f32((g_coord[0] + g_coord[1]) * (TILE_HEIGHT / 2) + OFFSET_Y),
    }
}

screen_to_iso :: proc(m_coord: rl.Vector2) -> [2]f32 {
    // Convert screen mouse coordinates to 2D isometric grid coordinates
    // Inverse transformation matrix logic
    x := m_coord[0] - OFFSET_X
    y := m_coord[1] - OFFSET_Y
    
    // Solve the system of equations for (x, y) grid space
    nx := (x / (TILE_WIDTH / 2) + y / (TILE_HEIGHT / 2)) / 2
    ny := (y / (TILE_HEIGHT / 2) - x / (TILE_WIDTH / 2)) / 2
    return [2]f32{math.floor(nx), math.floor(ny)}
}

draw_debug :: proc(hover: [2]f32) {
    /*
    various "debug" utils:
    - draw the FPS number
    - draw lines, h and v, representing the mid-screen
    */
    rl.DrawFPS(0, 0)
    pos := strings.clone_to_cstring(fmt.tprintf("(%d, %d)", i32(hover[0]), i32(hover[1])))
    defer delete(pos)
    rl.DrawText(pos, 0, 20, 20, GREEN)
    rl.DrawLineV(rl.Vector2{0, SCREEN_HEIGHT/2}, {SCREEN_WIDTH, SCREEN_HEIGHT/2}, GREEN)
    rl.DrawLineV(rl.Vector2{SCREEN_WIDTH/2, 0}, {SCREEN_WIDTH/2, SCREEN_HEIGHT}, GREEN)
}

main :: proc() {
    tracking: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking)

    defer {
        fmt.println("Memory statistics:")
        fmt.printfln("  Current:   %d bytes", tracking.current_memory_allocated)
        fmt.printfln("  Peak:      %d bytes", tracking.peak_memory_allocated)
        fmt.printfln("  Allocated: %d bytes total", tracking.total_memory_allocated)
        fmt.printfln("  Freed:     %d bytes total", tracking.total_memory_freed)
        fmt.printfln("  Allocations: %d", tracking.total_allocation_count)
        fmt.printfln("  Frees:       %d", tracking.total_free_count)

        if len(tracking.allocation_map) > 0 {
            fmt.eprintf("\nUnfreed allocations: %d\n", len(tracking.allocation_map))

            for _, entry in tracking.allocation_map {
                fmt.eprintf(
                    "  %d bytes allocated at %v\n",
                    entry.size,
                    entry.location,
                )
            }
        }

        if len(tracking.bad_free_array) > 0 {
            fmt.eprintf(
                "\nIncorrect frees: %d\n",
                len(tracking.bad_free_array),
            )

            for entry in tracking.bad_free_array {
                fmt.eprintf(
                    "  %p freed at %v\n",
                    entry.memory,
                    entry.location,
                )
            }
        }

        mem.tracking_allocator_destroy(&tracking)
    }
    
    rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT, .WINDOW_HIGHDPI})
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "isomap test")
    defer rl.CloseWindow()
    rl.SetTargetFPS(FPS)

    hover: rl.Vector2
    s: rl.Vector2
    is_hovered: bool
    fill_color: rl.Color
    for !rl.WindowShouldClose(){
        // update
        mouse_pos := rl.GetMousePosition()
        hover = screen_to_iso(mouse_pos)

        // render
        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND_BLACK)
        for row: i32 = 0 ; row < GRID_SIZE ; row += 1{
            for col: i32 = 0 ; col < GRID_SIZE ; col += 1{
                //Calculate screen coordinates for the corners of the tile
                s = iso_to_screen([2]i32{col, row})

                // Check if this specific tile is currently hovered
                is_hovered = (0.0 <= hover[0] && hover[0] < GRID_SIZE && 
                              0.0 <= hover[1] && hover[1] < GRID_SIZE && 
                              i32(hover[0]) == col && i32(hover[1]) == row)
                
                //Define the 4 corners of the isometric diamond
                p1 := rl.Vector2{s[0], s[1]}
                p2 := rl.Vector2{s[0] + TILE_WIDTH / 2, s[1] + TILE_HEIGHT / 2}
                p3 := rl.Vector2{s[0], s[1] + TILE_HEIGHT}
                p4 := rl.Vector2{s[0] - TILE_WIDTH / 2, s[1] + TILE_HEIGHT / 2}

                //Draw filled tile if hovered, otherwise draw basic grid lines
                if is_hovered{
                    fill_color = rl.SKYBLUE
                    rl.DrawTriangle(p1, p4, p3, fill_color)// Left half
                    rl.DrawTriangle(p1, p3, p2, fill_color) // Right half
                }
                
                //Draw the diamond outline
                rl.DrawLineV(p1, p2, rl.DARKGRAY)
                rl.DrawLineV(p2, p3, rl.DARKGRAY)
                rl.DrawLineV(p3, p4, rl.DARKGRAY)
                rl.DrawLineV(p4, p1, rl.DARKGRAY)
            }
        }
        draw_debug(hover)
        rl.EndDrawing()
    }
}