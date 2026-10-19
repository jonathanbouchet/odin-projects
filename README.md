# odin-projects
a collection of raylib app using Odin language

## compile
```bash
odin build . -debug -json-errors -show-timings -vet

# Total Time                         -   419.196 ms - 100.00%
# initialization                     -     1.436 ms -   0.34%
# parse files                        -    22.721 ms -   5.42%
# type check                         -    52.556 ms -  12.53%
# LLVM API Code Gen (   61 modules ) -   126.140 ms -  30.09%
# lld-link                           -   216.337 ms -  51.60%
```

## docs
```bash
odin doc .
```

## update version
```bash
git lfs install  
brew install git-lfs 
git lfs pull 
file vendor/raylib/macos/libraylib.a 
lipo -info vendor/raylib/macos/libraylib.a  
odin version
```

## Documentation I found useful
- Odin official overview: https://odin-lang.org/docs/overview/
- sage-code tutorial: https://odin-lang.org/docs/overview/
- intro (Sjoerd Wouters): https://sjoerdev.github.io/posts/odin-guide/
- SDL in Odin: https://www.youtube.com/playlist?list=PLO02jwa2ZaiDY7kVImqZUHDiuomsl7OdA
- OpenGL in Odin: https://github.com/bg-thompson/OpenGL-Tutorials-In-Odin
- KArl Zylinski's webpage: https://zylinski.se/
- Peter Mbanugo `Learn Odin in an Hour`'s blog: https://pmbanugo.me/series/odin-in-an-hour 

## Coding style

There is a commonly followed Odin convention, although the compiler does not require it.

The usual style is:

- `snake_case` for variables
- `snake_case` for procedures
- `Ada_Case` for types and structs
- `Ada_Case` for enum values
- `SCREAMING_SNAKE_CASE` for constants, when they are truly constants
- `Tabs` for indentation
- `Spaces` around operators
- `Opening braces` at the end of the line
This is the convention used by the Odin examples repository and much of Odin’s native code. 


- There should be a space around :=.
    - example:
    ```odin
    for i in 0..<count {
        // ...
    }
    ```

- The opening brace should be separated from the preceding expression by a space:

```odin
if condition {
	// ...
} else {
	// ...
}
```
- The exact flags can vary by Odin version, but -strict-style and -vet-tabs are useful for catching many convention and indentation issues.

```bash
odin build . -strict-style -vet-tabs -warnings-as-errors
```