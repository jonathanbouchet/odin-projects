package box2d_exploration

import "core:fmt"
import b2 "vendor:box2d"
import rl "vendor:raylib"
import "core:mem"
import "core:math"

WIDTH :: 600
HEIGHT :: 600
RAD2DEG :: 180.0

NUM_GROUND :: 10
NUM_BOX :: 1

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

Entity :: struct{
    bodyId: b2.BodyId,
	extent: rl.Vector2,
	texture: rl.Texture,
} 

draw_entity :: proc(entity: Entity){
    // The boxes were created centered on the bodies, but raylib draws textures starting at the top left corner.
	// b2Body_GetWorldPoint gets the top left corner of the box accounting for rotation.
    p:= b2.Body_GetWorldPoint(entity.bodyId, -entity.extent)
    rotation:= b2.Body_GetRotation(entity.bodyId)
    radians := b2.Rot_GetAngle(rotation)

    ps := rl.Vector2{p.x ,p.y}
    rl.DrawTextureEx(entity.texture, ps, RAD2DEG * radians, 1.0, rl.WHITE)

}

main :: proc(){
    show_memory()
    // fmt.println("hellope")
    rl.InitWindow(WIDTH, HEIGHT, "box2d")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    // 128 pixels per meter is a appropriate for this scene. The boxes are 128 pixels wide.
	lengthUnitsPerMeter := f32(128)
	b2.SetLengthUnitsPerMeter(lengthUnitsPerMeter);

    WorldDef := b2.DefaultWorldDef()
    fmt.printf("b2World: %v\n", WorldDef)

    // Realistic gravity is achieved by multiplying gravity by the length unit.
	WorldDef.gravity.y = f32(9.8) * lengthUnitsPerMeter
    fmt.println("gravity: ", WorldDef.gravity)
    worldId:= b2.CreateWorld(WorldDef)
    fmt.println("worldId: ", worldId)

    // texture
    groundTexture := rl.LoadTexture("ground.png")
    boxTexture := rl.LoadTexture("box.png")
    defer rl.UnloadTexture(groundTexture)
    defer rl.UnloadTexture(boxTexture)

    groundExtent := rl.Vector2{f32(0.5) * f32(groundTexture.width), f32(0.5) * f32(groundTexture.height)}
    boxExtent := rl.Vector2{f32(0.5) * f32(boxTexture.width), f32(0.5) * f32(boxTexture.height)}

    fmt.println("groupExtent: ", groundExtent)

    // These polygons are centered on the origin and when they are added to a body they
	// will be centered on the body position.
    groupPolygon := b2.MakeBox(f32(groundExtent.x), f32(groundExtent.y))
    boxPolygon := b2.MakeBox(f32(boxExtent.x), f32(boxExtent.y))

    ground_entities : [NUM_GROUND]Entity

    for i in 0..<NUM_GROUND{
        entity: ^Entity = &ground_entities[i]
        bodyDef: b2.BodyDef = b2.DefaultBodyDef()
        bodyDef.position = rl.Vector2{ (2. * f32(i) + 2.0) * f32(groundExtent.x), HEIGHT - groundExtent.y - 0.0}

        entity.bodyId = b2.CreateBody(worldId, bodyDef)
        entity.extent = groundExtent
        entity.texture = groundTexture
        shape_def:= b2.DefaultShapeDef()
        _ = b2.CreatePolygonShape(entity.bodyId, shape_def, &groupPolygon) // this requires the result to be handled
    }

    box_entities: [NUM_BOX]Entity

    for i in 0..<NUM_BOX{
        y:= HEIGHT - groundExtent.y - 400.0 - (f32(2.5) * f32(i) + 2.0) * boxExtent.y - 20.0
        x:= 0.25 * WIDTH + (3.0 * f32(1.0) - f32(i) - 3.0) * boxExtent.x
        entity: ^Entity = &box_entities[i]
        bodyDef: b2.BodyDef = b2.DefaultBodyDef()
        bodyDef.type = .dynamicBody

        bodyDef.position = rl.Vector2{ x, y }
        entity.bodyId = b2.CreateBody(worldId, bodyDef)
        entity.texture = boxTexture
        entity.extent = boxExtent
        shape_def := b2.DefaultShapeDef()
        _ = b2.CreatePolygonShape(entity.bodyId, shape_def, &boxPolygon)
    }

    // circular body
    tmp_body: b2.BodyDef = b2.DefaultBodyDef()
    tmp_body.type = .dynamicBody
    tmp_body.position = rl.Vector2{ 500, 50.0}

    ballBody: b2.BodyId = b2.CreateBody(worldId, tmp_body)
    circle: b2.Circle = {0, 0}
    circle.center = rl.Vector2{ 0.0, 0.0 }
    circle.radius = 30

    shape_def:= b2.DefaultShapeDef()
    shape_def.density = f32(1.0)
    shape_def.material.friction = f32(0.3)
    shape_def.material.restitution = f32(1)

    _ = b2.CreateCircleShape(ballBody, shape_def, &circle)

    pause: bool = true
    for !rl.WindowShouldClose(){
        // logic
        dt:= rl.GetFrameTime()
        //update
        if rl.IsKeyPressed(.SPACE){
            pause = !pause
        }
        if !pause {
			delta_time := rl.GetFrameTime()
			b2.World_Step(worldId, delta_time, 4)
		}

        //rendering
        rl.BeginDrawing()
        rl.ClearBackground({25, 25, 25, 255})
        for i in 0..<NUM_GROUND{
			draw_entity(ground_entities[i]);
		}

        for i in 0..<NUM_BOX{
			draw_entity(box_entities[i]);
		}
        ball_position:= b2.Body_GetPosition(ballBody)

        rl.DrawCircle(
            i32(ball_position.x),
            i32(ball_position.y),
            circle.radius ,
            rl.RED
        )
        rl.EndDrawing()
    }
}