package isometric_map

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

WIDTH :: 600
HEIGHT :: 600
TILE_SIZE :: 32
N_TILE :: 10
FPS :: 60
BACKGROUND :: rl.Color{0, 0, 28, 255}
BACKGROUND_BLACK :: rl.Color{20, 20, 20, 255 } // light black
GREEN :: rl.Color{57, 255, 20, 255}

Tile :: struct {
    i: i32,
    j: i32,
    tile_id: i32,
    tile_data: [4][2]i32,
}

World :: struct {
    grid_length_x: i32,
    grid_length_y: i32,
    width: i32,
    height: i32,
    tiles: [N_TILE * N_TILE]Tile,
}

cartesian_to_isometric :: proc(i, j: i32, tile_width: i32, tile_height: i32) -> (i32, i32){
    x_iso := (i - j)
    y_iso := (i + j) / 2 
    return x_iso, y_iso
}

grid_to_world :: proc(grid_x, grid_y: i32, tile_size: i32) -> [4][2]i32{
    tmp: [4][2]i32
    tmp[0][0], tmp[0][1] = grid_x * tile_size, grid_y * tile_size
    tmp[1][0], tmp[1][1] = grid_x * tile_size + tile_size, grid_y * tile_size
    tmp[2][0], tmp[2][1] = grid_x * tile_size + tile_size, grid_y * tile_size + tile_size
    tmp[3][0], tmp[3][1] = grid_x * tile_size, grid_y * tile_size + tile_size
    return tmp
}

make_world :: proc(w: World) -> [N_TILE * N_TILE]Tile{
    tmp: [N_TILE * N_TILE]Tile
    cnt: i32 = 0
    for i in 0..<w.grid_length_x{
        for j in 0..<w.grid_length_y{
            tile := Tile{i, j, cnt, grid_to_world(i, j, w.width)}
            tmp[cnt] = tile
            cnt += 1
        }
    }
    return tmp
}

draw_debug :: proc() {
    /*
    various "debug" utils:
    - draw the FPS number
    - draw lines, h and v, representing the mid-screen
    */
    rl.DrawFPS(0, 0)
    rl.DrawLineV(rl.Vector2{0, HEIGHT/2}, {WIDTH, HEIGHT/2}, GREEN)
    rl.DrawLineV(rl.Vector2{WIDTH/2, 0}, {WIDTH/2, HEIGHT}, GREEN)
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
    
    rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})
    rl.InitWindow(WIDTH, HEIGHT, "isomap")
    defer rl.CloseWindow()
    rl.SetTargetFPS(FPS)

    world:= World{grid_length_x=10, grid_length_y=10, width=WIDTH, height=HEIGHT}
    make_world(world)

    for !rl.WindowShouldClose(){
        rl.BeginDrawing()
        rl.ClearBackground(BACKGROUND_BLACK)
        draw_debug()
        rl.EndDrawing()
    }

}