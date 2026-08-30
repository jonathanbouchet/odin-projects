package main
import "core:fmt"
import rl "vendor:raylib"
import "core:encoding/json"
import "core:os"

Level :: struct {
    platforms: [dynamic]rl.Vector2,
    debug: bool,
    name: string
}

main :: proc(){
    fmt.println("hellope")
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
    defer delete(level.platforms)
    fmt.println("Platforms:", level.platforms)
}
