package main

import "core:mem"
import "core:fmt"
import rl "vendor:raylib"

BG :: rl.Color{0, 0, 0x1C, 0xFF}
FG :: rl.Color{0, 0xDF, 0, 0xFF}
FADED :: rl.Color{0, 0xDF, 0, 0x44}
WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

MOVING_RECT_SIZE :: rl.Vector2{90, 140}
SCREEN_CENTER :: rl.Vector2{WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2}
ITERATIONS :: 32

main :: proc() {
    tracking: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking)

    defer {
        fmt.printfln(
            "Current memory: %d bytes, peak memory: %d bytes",
            tracking.current_memory_allocated,
            tracking.peak_memory_allocated,
        )

        if len(tracking.allocation_map) > 0 {
            fmt.eprintln("Unfreed allocations:")

            for _, entry in tracking.allocation_map {
                fmt.eprintf(
                    "- %d bytes @ %v\n",
                    entry.size,
                    entry.location,
                )
            }
        }

        mem.tracking_allocator_destroy(&tracking)
    }

    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "AABB Discrete")
    defer rl.CloseWindow()

    static_rects: [dynamic]rl.Rectangle
    defer delete(static_rects)

	append(&static_rects, rl.Rectangle{200, 100, 200, 300})
	append(&static_rects, rl.Rectangle{400, 100, 200, 300})
	append(&static_rects, rl.Rectangle{200, 400, 200, 300})
	append(&static_rects, rl.Rectangle{800, 400, 40, 300})

    old_position: rl.Vector2

    for !rl.WindowShouldClose() {
        mouse_position := rl.GetMousePosition()
        if rl.IsMouseButtonPressed(.LEFT) {
			old_position = mouse_position
		}

        moving_rect := rect_from_pos_size(mouse_position - MOVING_RECT_SIZE / 2, MOVING_RECT_SIZE)

        rl.BeginDrawing()
        rl.ClearBackground(BG)
        rl.DrawRectangleLinesEx(moving_rect, 4, rl.WHITE)
        for static_rect in static_rects {
            if aabb_intersects_aabb(moving_rect, static_rect) {
                overlap := get_overlap(moving_rect, static_rect)
                rl.DrawRectangleRec(overlap, FADED)
            } else {
                rl.DrawRectangleLinesEx(static_rect, 4, rl.WHITE)
            }
            rl.DrawRectangleLinesEx(static_rect, 4, FG)
		}
        rl.EndDrawing()
    }
}

rect_from_pos_size :: proc(pos, size: rl.Vector2) -> rl.Rectangle {
    return rl.Rectangle{pos.x, pos.y, size.x, size.y}
}

aabb_intersects_aabb :: proc(a, b: rl.Rectangle) -> bool {
    if a.x >= b.x + b.width do return false // too far right
    if a.y >= b.y + b.height do return false // too far down
    if a.x + a.width <= b.x do return false // too far left
    if a.y + a.width <= b.y do return false // too far up
    return true
}

get_overlap :: proc(a, b: rl.Rectangle) -> rl.Rectangle {
    x := max(a.x, b.x)
	y := max(a.y, b.y)
    z := min(a.x + a.width, b.x + b.width)
	w := min(a.y + a.height, b.y + b.height)
    return rl.Rectangle{x, y, z - x, w - y}
}