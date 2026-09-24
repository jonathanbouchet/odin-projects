package threeDgrid

import rl "vendor:raylib"

update_shader_values :: proc(
    light_direction: ^[3]f32, 
    light_color: ^[3]f32, 
    ambient_color: ^[3]f32,
    light_direction_loc: int, 
    light_color_loc: int, 
    ambient_color_loc: int,
    shader: rl.Shader) {
    rl.SetShaderValue(
        shader,
        light_direction_loc,
        light_direction,
        rl.ShaderUniformDataType.VEC3,
    )
    rl.SetShaderValue(
        shader,
        light_color_loc,
        light_color,
        rl.ShaderUniformDataType.VEC3,
    )
    rl.SetShaderValue(
        shader,
        ambient_color_loc,
        ambient_color,
        rl.ShaderUniformDataType.VEC3,
    )
}
