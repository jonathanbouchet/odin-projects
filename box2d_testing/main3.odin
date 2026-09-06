package box2d_refactoring

import "core:fmt"
import b2 "vendor:box2d"
import rl "vendor:raylib"
import "core:mem"

WIDTH :: 640
HEIGHT :: 640
RAD2DEG :: 180.0

block :: struct {
    position:  rl.Vector2,
    size: rl.Vector2,
    bodyId: b2.BodyId,
    shapeId: b2.ShapeDef,
    color: rl.Color
}

create_rigid_body :: proc(position: rl.Vector2, size: rl.Vector2, worldId: b2.WorldId, body_type: b2.BodyType, color: rl.Color) -> block{
    extent:= size
    polygon := b2.MakeBox(f32(0.5 * extent.x), f32(0.5 * extent.y)) //MakeBox takes half width and half height

    body_def:= b2.DefaultBodyDef()
    body_def.type = body_type
    body_def.position = rl.Vector2{position.x, position.y + extent.y/2.0}

    bodyId:= b2.CreateBody(worldId, body_def)
    shape_def:= b2.DefaultShapeDef()
    _ = b2.CreatePolygonShape(bodyId, shape_def, &polygon) // this requires the result to be handled

    block := block{position=position, size=extent, bodyId=bodyId, shapeId=shape_def, color=color}
    return block
}

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

create_world :: proc() -> b2.WorldId{
    // 32 pixels per meter is a appropriate for this scene.
	lengthUnitsPerMeter := f32(64) // height of floor and wall
	b2.SetLengthUnitsPerMeter(lengthUnitsPerMeter);

    WorldDef := b2.DefaultWorldDef()
    fmt.printf("b2World: %v\n", WorldDef)

    // Realistic gravity is achieved by multiplying gravity by the length unit.
	WorldDef.gravity.y = f32(9.8) * lengthUnitsPerMeter
    worldId:= b2.CreateWorld(WorldDef)
    return worldId
}

draw_debug :: proc() {
    rl.DrawFPS(0, 0)
    rl.DrawLineV(rl.Vector2{0, HEIGHT/2}, {WIDTH, HEIGHT/2}, rl.Color{57, 255, 20, 255})
    rl.DrawLineV(rl.Vector2{WIDTH/2, 0}, {WIDTH/2, HEIGHT}, rl.Color{57, 255, 20, 255})
}

main :: proc(){
    show_memory()
    rl.InitWindow(WIDTH, HEIGHT, "box2d")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)
    worldId := create_world()
    defer b2.DestroyWorld(worldId)

    floor:= create_rigid_body(
        size=rl.Vector2{WIDTH, 32.0}, 
        position=rl.Vector2{0, HEIGHT - 32}, 
        worldId=worldId, 
        body_type=.staticBody,
        color=rl.DARKBLUE
    )

    fmt.printf("floor: %v\n", floor)

    // circular body
    tmp_body: b2.BodyDef = b2.DefaultBodyDef()
    tmp_body.type = .dynamicBody
    tmp_body.position = rl.Vector2{WIDTH/2, 200.0}
    tmp_body.linearVelocity = rl.Vector2{0, 100}

    ballBody: b2.BodyId = b2.CreateBody(worldId, tmp_body)
    circle: b2.Circle = {0, 0}
    circle.center = rl.Vector2{ 0.0, 0.0 }
    circle.radius = 30

    ball_shape:= b2.DefaultShapeDef()
    ball_shape.enableContactEvents = true // Crucial for callbacks/events
    ball_shape.density = f32(1)
    ball_shape.material.friction = f32(0.0)
    ball_shape.material.restitution = f32(0.1)
    _ = b2.CreateCircleShape(ballBody, ball_shape, &circle)


    pause:= true

    for !rl.WindowShouldClose(){
        // logic

        //update
        if rl.IsKeyPressed(.SPACE){
            pause = !pause
        }
        if !pause {
			delta_time := rl.GetFrameTime()
			b2.World_Step(worldId, delta_time, 4)

            // Fetch collision events for this step
            contact_events := b2.World_GetContactEvents(worldId)
            
            // Process touch/begin events
            for i in 0..<contact_events.beginCount {
                begin_event := contact_events.beginEvents[i]
                fmt.printfln("Collision detected between shapes %v and %v!", begin_event.shapeIdA, begin_event.shapeIdB)
            }
		}

        // Read positions after the physics step.
        ball_center := b2.Body_GetPosition(ballBody)

        // render
        rl.BeginDrawing()
        rl.ClearBackground({20, 20, 20, 255})

        rl.DrawRectangleV(floor.position, floor.size, floor.color)
        rl.DrawCircleV(ball_center,circle.radius,rl.DARKGREEN)

        draw_debug()
        rl.EndDrawing()
    }

}