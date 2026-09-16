package threeDgrid

import "core:fmt"
import "core:mem"
import "core:math"
import rl "vendor:raylib"

SCREEN_WIDTH :: 600
SCREEN_HEIGHT :: 600
TARGET_FPS :: 60

show_memory :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer {
        for _, entry in track.allocation_map {
            fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
        }
        for entry in track.bad_free_array {
            fmt.eprintf("%v bad free\n", entry.location)
        }
        mem.tracking_allocator_destroy(&track)
    }
}

main :: proc() {
    show_memory()
    // raylib window
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "3D model")
    defer rl.CloseWindow()

    // camera
    camera := rl.Camera3D{
        position   = { 0.0, 4.0, 10.0 },
        target     = { 0.0, 0.0, 0.0 },
        up         = { 0.0, 1.0, 0.0 },
        fovy       = 60.0,
        projection = .PERSPECTIVE,
    }
    rl.SetTargetFPS(TARGET_FPS)
    model := rl.LoadModelFromMesh(rl.GenMeshCube(2.0, 2.0, 2.0))
    bb := rl.GetModelBoundingBox(model)
    fmt.printfln("bb: %v", bb)
    position := rl.Vector3{ 1.0, 1.0, 1.0 } // center of the cube so it will appear at gridX=0, gridZ=0 if W,H,L = 2
    // need to update BB if position is shifted from 0, 0, 0
    bb.min += position
    bb.max += position
    tileSize := 2
    gridX: i32
    gridZ: i32
    is_hit: bool

    // Main game loop
    for !rl.WindowShouldClose() {
        // update 
        is_hit = false
        dt := rl.GetFrameTime()
        mouse_pos := rl.GetMousePosition()
        ray := rl.GetScreenToWorldRay(mouse_pos, camera)
        groundY := f32(0.0)

        // Ray: position + direction * t
        // Find t where the ray reaches y = groundY:
        // ray.position.y + ray.direction.y * t = groundY

        groundPosition := rl.Vector3{ 0.0, 0.0, 0.0 }

        if math.abs(ray.direction.y)> 0.0001{
            t := (groundY - ray.position.y) / ray.direction.y
            if t > 0.0{
                groundPosition = ray.position + ray.direction * t
            }
            gridX = i32(math.floor_f32(groundPosition.x / f32(tileSize)))
            gridZ = i32(math.floor_f32(groundPosition.z / f32(tileSize)))
            // fmt.printfln("gridX, gridY: %v %v", gridX, gridZ)
        }

        hit := rl.GetRayCollisionBox(ray, bb)

        if hit.hit{
            worldPosition := hit.point
            fmt.printfln("world position: %v", worldPosition)
            is_hit = true
        }

        // render
        rl.BeginDrawing()
        rl.ClearBackground({ 20, 20, 20, 255 })

        rl.BeginMode3D(camera)
        rl.DrawModel(model, position, 1.0, rl.RED)
        rl.DrawCubeWires(position, 2.0, 2.0, 2.0, rl.GREEN if is_hit else rl.GRAY)
        rl.DrawGrid(10, 2.0)
        rl.DrawLine3D(rl.Vector3{ 0.0, 0.01, -10.0 }, rl.Vector3{ 0.0, 0.01, 10.0 }, rl.DARKBLUE )
        rl.DrawLine3D(rl.Vector3{ -10.0, 0.01, 0.0 }, rl.Vector3{ 10.0, 0.01, 0.0 }, rl.DARKBLUE )
        rl.EndMode3D()

        grid_pos_text := fmt.ctprintf("X:%v Z:%v", gridX, gridZ)
        is_detected_text := fmt.ctprintf("Mouse Hover: %v", is_hit)
        rl.DrawFPS(0, 0)
        rl.DrawText(grid_pos_text, 0, 20, 20, rl.GREEN)
        rl.DrawText(is_detected_text, 0, 40, 20, rl.GREEN)

        rl.EndDrawing()
    }
}