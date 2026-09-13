- about: script that loads a 3D model, as `GLTF` format:
    - `Graphics Library Transmission Format` is an open-standard, lightweight file format used to store and transmit 3D models and scenes

- camera is almost free:
    - `Left mouse drag`: screen-space panning.
    - `Left/right arrows`: horizontal orbit around the target, rotating around the Y axis.
    - `Up/down arrows`: zoom in and out by changing the camera distance.

---

## Tree
```bash
├── 3d_camera_model
│   └── Contents
│       ├── Info.plist
│       └── Resources
│           ├── DWARF
│           │   └── 3d_camera_model
│           └── Relocations
│               └── aarch64
│                   └── 3d_camera_model.yml
├── README.md
├── assets
│   ├── building_A.bin
│   ├── building_A.gltf
│   ├── building_A_withoutBase.gltf
│   └── citybits_texture.png
└── main.odin
```

- when loading a `GLTF` format, the `bin` and `texture` should be in the same directory
- looking at the `gltf` file:
```bash
"images" : [
        {
            "mimeType" : "image/png",
            "name" : "citybits_texture",
            "uri" : "citybits_texture.png"
        }
    ],
...
"buffers" : [
        {
            "byteLength" : 49512,
            "uri" : "building_A.bin"
        }
]
```

