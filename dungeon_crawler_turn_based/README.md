## issue with `texture`
I'm applying a `texture2D` on a mesh like this:

```odin
texture_original := rl.LoadTexture('wall_64x64.png')
defer rl.UnloadTexture(texture_original)
model := rl.LoadModelFromMesh(rl.GenMeshCube(1.0, 1.0, 1.0)) // full cube
model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = texture_original
```

- `wall_64x64.png` is a png made with `Aseprite`. 
- The model is a simple cube on which I applied the texture.
- I then display the mesh with the following:

```odin
position_cube := rl.Vector3{ -10.0, 1.5, 0.0 } // Set model position
rl.DrawModel(model, position_cube, 1.0, rl.RAYWHITE)
```

- However I noticed that the texture is flipped around Z, meaning the details on the bottom of the png now appear on top of the cube.
- reason:
>  That’s usually a texture-coordinate orientation mismatch: image files are commonly treated as top-left-origin, while the generated mesh’s UVs may map the vertical axis the other way. Flip the image vertically before uploading it, or invert the mesh UV v values.

### Solution 1
- by modyfing the original image

```odin
image := rl.LoadImage('wall_64x64.png')
defer rl.UnloadImage(image)

rl.ImageFlipVertical(&image)
texture_original := rl.LoadTextureFromImage(image)
defer rl.UnloadTexture(texture_original)
```

### Solution 2
- by using `shaders`

```cpp
void main()
{
    vec2 uv = vec2(fragTexCoord.x, 1.0 - fragTexCoord.y);
    vec4 baseColor = texture(texture0, uv) * fragColor;

    vec3 normal = normalize(fragNormal);
    // ...rest of your lighting code
}
```

- I choose `solution 2` because I plan to add some lighting. However it had some side effects on the `ceiling`
- this sprite has a black background with color the same of the game window background. This was a trick to add transparency for the walls.
- but as a result, it meant now that the ceiling was also reflecting the light from the source, breaking the _mood_ of the level
- a quick fix was to redo the sprite w/o background color