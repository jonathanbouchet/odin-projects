package main

import rl "vendor:raylib"

Lighting :: struct {
    light_direction_loc: i32,
    light_color_loc: i32,
    ambient_color_loc: i32,
    light_direction: [3]f32,
    light_color: [3]f32,
    ambient_color: [3]f32,
}

set_lighting :: proc(game: ^Game){
    light: Lighting
    light.light_direction = {0, 0, 0} // initial values at 0 completely disable the shader
	light.light_color = {1.0, 1.0, 1.0}
    light.ambient_color = {1.0, 1.0, 1.0}

    light.light_direction_loc = rl.GetShaderLocation(game.shader, "lightDirection")
    light.light_color_loc = rl.GetShaderLocation(game.shader, "lightColor")
    light.ambient_color_loc = rl.GetShaderLocation(game.shader, "ambientColor")

    game.lighting = light
}

add_shader_to_model :: proc(game: ^Game) {
    model_names := [4]string{"wall", "floor", "ceiling_1", "door"}
    for model_name in model_names{
        for i in 0..<int(game.models[model_name].materialCount){
            game.models[model_name].materials[i].shader = game.shader
        }
    }
}

update_shader_values :: proc(game: ^Game){
    ld: ^[3]f32 = &game.lighting.light_direction
    lc: ^[3]f32 = &game.lighting.light_color
    ac: ^[3]f32 = &game.lighting.ambient_color
    rl.SetShaderValue(
        game.shader,
        int(game.lighting.light_direction_loc),
        ld,
        rl.ShaderUniformDataType.VEC3,
    )
    rl.SetShaderValue(
        game.shader,
        int(game.lighting.light_color_loc),
        lc,
        rl.ShaderUniformDataType.VEC3,
    )
    rl.SetShaderValue(
        game.shader,
        int(game.lighting.ambient_color_loc),
        ac,
        rl.ShaderUniformDataType.VEC3,
    )
}