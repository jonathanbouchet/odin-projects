package main

import "core:testing"

@(test)
test_export_json_compact :: proc(t: ^testing.T) {
    // no errors
    report := Report{title = "Systems Notes", author = "A. Lovelace", pages = 42}
    out := export_json(Json_Exporter{pretty = false}, report)
    defer delete(out)
    testing.expect_value(t, out, `{"title": "Systems Notes", "author": "A. Lovelace", "pages": 42}`)
}

@(test)
test_export_json_compact_v2 :: proc(t: ^testing.T) {
    // warning reported about memory leak
    report := Report{title = "Systems Notes", author = "A. Lovelace", pages = 42}
    out := export_json(Json_Exporter{pretty = false}, report)
    // defer delete(out)
    testing.expect_value(t, out, `{"title": "Systems Notes", "author": "A. Lovelace", "pages": 42}`)
}

@(test)
test_export_json_compact_v3 :: proc(t: ^testing.T) {
    report := Report{title = "Systems Notes", author = "A. Lovelace", pages = 42}
    out := export_json(Json_Exporter{pretty = false}, report)
    defer delete(out)
    testing.expect_value(t, out, `{"title": "Systems Notes", "author": "A. Lovelace", "pages": 43}`)
}