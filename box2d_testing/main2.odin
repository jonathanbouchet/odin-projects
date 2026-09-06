package box2d_better

import "core:fmt"
import b2 "vendor:box2d"
import rl "vendor:raylib"
import "core:mem"

WIDTH :: 640
HEIGHT :: 640
RAD2DEG :: 180.0
NUM_BLOCKS :: 9

rigid_body :: struct {
    position:  rl.Vector2,
    size: rl.Vector2,
    body_type: b2.BodyType,
    shape_def: b2.ShapeDef,  
    type: b2.BodyType
}

create_rigid_body :: proc(position: rl.Vector2, size: rl.Vector2, worldId: b2.WorldId, body_type: b2.BodyType) -> rl.Vector2{
    extent:= size
    polygon := b2.MakeBox(f32(0.5 * extent.x), f32(0.5 * extent.y)) //MakeBox takes half width and half height
    fmt.printf("floor extent: %v\nfloor polygon: %v\n", extent, polygon)
    body_def:= b2.DefaultBodyDef()
    body_def.type = body_type
    body_def.position = rl.Vector2{position.x, position.y}
    bodyId:= b2.CreateBody(worldId, body_def)
    shape_def:= b2.DefaultShapeDef()
    _ = b2.CreatePolygonShape(bodyId, shape_def, &polygon) // this requires the result to be handled
    return extent
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
	WorldDef.gravity.y = f32(0.1) * lengthUnitsPerMeter
    fmt.println("gravity: ", WorldDef.gravity)
    worldId:= b2.CreateWorld(WorldDef)
    fmt.println("worldId: ", worldId)
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

    floor_extent:= create_rigid_body(
        size=rl.Vector2{WIDTH, 32.0}, 
        position=rl.Vector2{WIDTH/2, HEIGHT - 32}, 
        worldId=worldId, 
        body_type=.staticBody
    )

    ceiling:= create_rigid_body(
        size=rl.Vector2{WIDTH, 32.0}, 
        position=rl.Vector2{WIDTH/2, 32/2}, 
        worldId=worldId, 
        body_type=.staticBody
    )

    left_wall:= create_rigid_body(
        size=rl.Vector2{32, HEIGHT}, 
        position=rl.Vector2{32/2, HEIGHT/2}, 
        worldId=worldId, 
        body_type=.staticBody
    )

    right_wall:= create_rigid_body(
        size=rl.Vector2{32, HEIGHT}, 
        position=rl.Vector2{WIDTH - 32/2, HEIGHT/2}, 
        worldId=worldId, 
        body_type=.staticBody
    )

    // circular body
    tmp_body: b2.BodyDef = b2.DefaultBodyDef()
    tmp_body.type = .dynamicBody
    tmp_body.position = rl.Vector2{WIDTH/2, 200.0}
    tmp_body.linearVelocity = rl.Vector2{1000, 1000}

    ballBody: b2.BodyId = b2.CreateBody(worldId, tmp_body)
    circle: b2.Circle = {0, 0}
    circle.center = rl.Vector2{ 0.0, 0.0 }
    circle.radius = 30

    ball_shape:= b2.DefaultShapeDef()
    ball_shape.enableContactEvents = true // Crucial for callbacks/events
    ball_shape.density = f32(1)
    ball_shape.material.friction = f32(0.0)
    ball_shape.material.restitution = f32(1.0)
    _ = b2.CreateCircleShape(ballBody, ball_shape, &circle)

    // paddle
    tmp_body2: b2.BodyDef = b2.DefaultBodyDef()
    tmp_body2.type = .kinematicBody
    tmp_body2.position = rl.Vector2{WIDTH/2 - 50/2, HEIGHT - 100.0}
    pol := b2.MakeBox(f32(50), f32(10)) // remember: half dimension !!

    paddleBody: b2.BodyId = b2.CreateBody(worldId, tmp_body2)
    paddle_shape:= b2.DefaultShapeDef()
    paddle_shape.enableContactEvents = true // Crucial for callbacks/events
    paddle_shape.density = f32(1)
    paddle_shape.material.friction = f32(1.0)
    paddle_shape.material.restitution = f32(1.0)
    _ = b2.CreatePolygonShape(paddleBody, paddle_shape, &pol)

    Blocks :: struct{
        extent: [NUM_BLOCKS]rl.Vector2,
        id: [NUM_BLOCKS]i32
    }
    blocks: Blocks

    for i in 0..<NUM_BLOCKS{
        pos:= rl.Vector2{f32(32.0) + f32(64*i), 100}
        block_extent:= create_rigid_body(
            size=rl.Vector2{32, 16.0}, 
            position=pos, 
            worldId=worldId, 
            body_type=.staticBody
        )
        blocks.extent[i] = pos
        blocks.id[i] = i32(i)
    }

    fmt.printf("number of blocks: %d\n", len(blocks.extent))
    for i in 0..<NUM_BLOCKS{
        fmt.printf("block: %d, pos:%v\n", i, blocks.extent[i])
    }

    pause:= true

    for !rl.WindowShouldClose(){
        // logic
        if rl.IsKeyDown(.RIGHT){
            b2.Body_SetLinearVelocity(paddleBody, rl.Vector2{400,0})
        } else if rl.IsKeyDown(.LEFT){
            b2.Body_SetLinearVelocity(paddleBody, rl.Vector2{-400,0})
        }
        else {
            b2.Body_SetLinearVelocity(paddleBody, rl.Vector2{0,0})
        }

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
        paddle_center := b2.Body_GetPosition(paddleBody)
        ball_center := b2.Body_GetPosition(ballBody)

        // render
        rl.BeginDrawing()
        rl.ClearBackground({20, 20, 20, 255})
        // Paddle physics size is 100 x 20 because MakeBox uses half-extents.
        paddle_size := rl.Vector2{100, 20}
        paddle_top_left := paddle_center - paddle_size * 0.5

        rl.DrawRectangleV({0, HEIGHT - floor_extent.y}, floor_extent, rl.DARKBLUE)
        rl.DrawRectangleV({0, 0}, ceiling, rl.DARKPURPLE)
        rl.DrawRectangleV({0, 0 - floor_extent.y}, left_wall, rl.RED) // coordinate should be the top left corner of the extent
        rl.DrawRectangleV({WIDTH - 32 , 0 - floor_extent.y}, right_wall, rl.RED) // coordinate should be the top left corner of the extent
        rl.DrawRectangleV(paddle_top_left,paddle_size,rl.RAYWHITE)
        rl.DrawCircleV(ball_center,circle.radius,rl.DARKGREEN)

        for i in 0..<NUM_BLOCKS{
            rl.DrawRectangleV(blocks.extent[i],rl.Vector2{32,16}, rl.YELLOW)
        }
        draw_debug()
        rl.EndDrawing()
    }

}