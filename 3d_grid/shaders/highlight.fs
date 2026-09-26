#version 330

// Input variables from vertex shader
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform textures
uniform sampler2D albedoMap; // Raylib automatically passes MATERIAL_MAP_ALBEDO/DIFFUSE here

// Custom color modification uniform
uniform vec4 colMod; // RGBA multiplier or addition

// Output color
out vec4 finalColor;

void main()
{
    // 1. Sample the core albedo/base color from the .glb texture
    vec4 albedo = texture(albedoMap, fragTexCoord);
    
    // 2. Perform color modification (Example: Tint multiplication)
    albedo *= fragColor; // Vertex tinting if passed via DrawModel
    albedo *= colMod;    // Custom uniform adjustments
    
    // NOTE: For a full PBR shader, you would pass this modified 'albedo' 
    // into your Cook-Torrance BRDF or lighting equations here.
    
    finalColor = albedo; 
}
