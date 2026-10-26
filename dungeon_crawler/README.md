## main idea
- 1st person dungeon crawler
- idea is to define a map / level as a grid of 10x10 (currently) and place textures on each of the tiles:
    - initial test was to _hardcode_ the location of the tiles given that each texture is mapped to a CubeMesh of size (1,0.001, 1), in the case of XZ plane
    ```odin
    for j in 0..<TILE_Y{
            for i in 0..<TILE_X {
                x = -4.5 + f32(i*1.0)
                y = 0.5 + f32(j*1.0)
                z = -5.0
                rl.DrawModelEx(wall, rl.Vector3{x, y, z}, rl.Vector3{1, 0, 0}, 0.0, 1.0, rl.RAYWHITE)
            }
        }
    ```
    - the second test (currently coded) is to make a map by hand and place each tile in an [10x10] array for each direction (`LEFT`, `RIGHT` or `BACK` walls):
    ```bash
     {
            "data":[
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0,
                1,0,0,0,0,0,0,0,0,0
            ],
            "direction":"left"
        },
    ```
    - the final version should be a map generated from `Tiled`
## Assets
- each texture is a `32x32` pixels
