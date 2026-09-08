- this is a test to use [box3d](https://box2d.org/documentation3d/index.html) as physics engine with `Raylib`

---
## 2026-09-07
- I'm using `Dear Imgui` so you need to replace these lines with your setup
```odin
import imgui "../../../ODIN_REPO/external_packages/odin-imgui-main"
import rlimgui "../../../ODIN_REPO/external_packages/backend/rlimgui"
```

```odin
worldDef := b3.DefaultWorldDef()
worldDef.gravity = rl.Vector3{0.0, -10.0, 0.0} 

// not valid: Odin’s named arguments can only refer to parameters declared by the procedure. They cannot target nested fields
// shapeDef := b3.DefaultShapeDef(
//       density = 1.0,
//        baseMaterial.friction = 0.1
// )
```
