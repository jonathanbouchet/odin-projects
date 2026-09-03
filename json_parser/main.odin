package main
import "core:fmt"
import rl "vendor:raylib"
import "core:encoding/json"
import "core:os"
import "core:mem"

Level :: struct {
    platforms: [dynamic]rl.Vector2,
    debug: bool,
    name: string
}

main :: proc(){
    fmt.println("hellope")
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
    level: Level
    data, success := os.read_entire_file("level.json", context.temp_allocator)

    if success != nil {
        fmt.println("Failed to read file.")
        return
    } 
    fmt.println("File read successfully")
    fmt.println(data)
    err := json.unmarshal(data, &level)
    if err != nil {
        fmt.printf("JSON Parsing Error: %v\n", err)
        return
    }
    // defer delete(level.platforms)
    // defer delete(level.name)
    fmt.printf("debug: %v, type: %v\n", level.platforms[:], typeid_of(type_of(level.platforms)))
    fmt.printf("debug: %v, type: %v\n", level.debug, typeid_of(type_of(level.debug)))
    fmt.printf("name: %v, type: %v\n",level.name, typeid_of(type_of(level.name)))
}
