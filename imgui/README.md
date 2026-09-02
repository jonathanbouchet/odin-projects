- this is a short recipe to install `Dear ImGui`
---
1. git clone `Dear Imgui` bindings: https://gitlab.com/L-4/odin-imgui

2. get the latest (as of 2026-09-01) Raylib backend for Dear ImGui for the odin bindings: https://gist.github.com/ctzcs/8ab847dc956717b8d897a98e23e8c89a

3. in my case, I created another folder where I'm adding these external packages:
```bash
ls external_packages 
backend
odin-imgui
```
- the file in step 2 has been renamed to:
```bash
external_packages/backend/rlimgui/rlimgui.odin
```

4. run the `python` script:
```python
python build.py
```
I got some warnings because of using a newer version of python
```bash
Warning: odin-imgui has been tested against Python version 3.12.2. (Yours: 3.14.4 (main, Apr  7 2026, 13:13:20) [Clang 16.0.0 (clang-1600.0.26.6)])
The script will still likely work, but it is untested!
```
But i created the executable (on mac): `imgui_darwin_arm64.a`

5. in `external_packages/backend/rlimgui/rlimgui.odin`, replace:
```bash
import imgui "../"
```
by the location of the repo (step 1)
```
import imgui "../../odin-imgui"
```

6. finally in your `main.odin` game file, include the 2 external packages:

```odin
import "core:fmt"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl" // Required for modern Odin raylib integrations
import imgui "../../external_packages/odin-imgui"
import rlimgui "../../external_packages/backend/rlimgui"
```