package main

import rl "vendor:raylib"

add_shader_to_model :: proc(game: ^Game) {
    model_names := [4]string{"wall", "floor", "ceiling_1", "door"}
    for model_name in model_names{
        for i in 0..<int(game.models[model_name].materialCount){
            game.models[model_name].materials[i].shader = game.shader
        }
    }
}

update_shader_values :: proc(game: ^Game){
    ld: ^[3]f32 = &game.light_direction
    lc: ^[3]f32 = &game.light_color
    ac: ^[3]f32 = &game.ambient_color
    rl.SetShaderValue(
        game.shader,
        int(game.light_direction_loc),
        ld,
        rl.ShaderUniformDataType.VEC3,
    )
    rl.SetShaderValue(
        game.shader,
        int(game.light_color_loc),
        lc,
        rl.ShaderUniformDataType.VEC3,
    )
    rl.SetShaderValue(
        game.shader,
        int(game.ambient_color_loc),
        ac,
        rl.ShaderUniformDataType.VEC3,
    )
}