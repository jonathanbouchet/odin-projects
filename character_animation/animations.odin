package main

import "core:os"
import "core:strings"
import "core:fmt"
import rl "vendor:raylib"

Animation_Frames :: struct {
    name: ANIMATION_NAME,
    textures: [dynamic]rl.Texture,
}

Player_Animations :: struct {
    animations: [8]Animation_Frames,
}

load_textures_from_directory :: proc(directory: string) -> [dynamic]rl.Texture{
    dir_handle, open_err := os.open(directory)
    if open_err != nil {
        fmt.eprintln("Failed to open directory:", open_err)
        // TO DO: return empty
        // return
    }
    defer os.close(dir_handle)

    // Read all contents (-1 tells it to read everything)
    file_infos, read_err := os.read_dir(dir_handle, -1, context.temp_allocator)
    if read_err != nil {
        fmt.eprintln("Failed to read directory:", read_err)
        // TO DO: return empty or multiple type
        // return
    }
    defer os.file_info_slice_delete(file_infos, context.temp_allocator) // Free allocated slice memory

    // This assumes the directory contains only the animation PNG files.
    count := len(file_infos)

    fmt.printfln("Number of files: %d", count)
    textures_data:= make([dynamic]rl.Texture, count)

    for i in 0..<count {
        path := fmt.tprintf("%s/%d.png", directory, i)
        path_cstring := strings.clone_to_cstring(path)
        texture := rl.LoadTexture(path_cstring)
        delete(path_cstring)
        append(&textures_data, texture)
    }

    return textures_data
}
