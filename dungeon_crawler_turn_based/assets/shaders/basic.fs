#version 330

in vec2 fragTexCoord;
in vec3 fragNormal;
in vec4 fragColor;

uniform sampler2D texture0;

uniform vec3 lightDirection;
uniform vec3 lightColor;
uniform vec3 ambientColor;

out vec4 finalColor;

void main()
{
    vec2 uv = vec2(fragTexCoord.x, 1.0 - fragTexCoord.y); // used to flip texture back to original
    vec4 baseColor = texture(texture0, uv) * fragColor;
    //vec4 baseColor =texture(texture0, fragTexCoord) * fragColor;

    vec3 normal = normalize(fragNormal);

    // Direction from the surface toward the light
    vec3 toLight = normalize(-lightDirection);

    // Surface brightness based on its angle to the light
    float brightness = max(dot(normal, toLight), 0.0);

    vec3 lighting =
        ambientColor +
        brightness * lightColor;

    finalColor = vec4(
        baseColor.rgb * lighting,
        baseColor.a
    );
}
