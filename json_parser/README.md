- adding tracking memeory allocator

- in this example, I read the following JSON into a `structure`:
```json
{
    "platforms":[[-20.00000000,10.00000000]],
    "debug": true,
    "name": "app"
}
```
```odin
Level :: struct {
    platforms: [dynamic]rl.Vector2,
    debug: bool,
    name: string
}
```

- with `defer delete`, the memory tracker shows:
```bash
/Users/jonathanbouchet/WORK/ODIN_REPO/Odin/core/encoding/json/unmarshal.odin(804:11) leaked 8 bytes
/Users/jonathanbouchet/WORK/ODIN_REPO/Odin/core/encoding/json/unmarshal.odin(279:9) leaked 4 bytes
```

- when adding the following:
```odin
defer delete(level.platforms)
defer delete(level.name)
```

- notes:
    - I tried `defer delete(level)` or `defer delete(level.debug)`, but got compiler error:
    ```bash
    Error: No procedures or ambiguous call for procedure group 'delete' that match with the given arguments 
    ```