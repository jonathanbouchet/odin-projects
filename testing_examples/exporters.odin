package main

import "core:fmt"
import "core:strings"

Report :: struct {
    title:  string,
    author: string,
    pages:  int,
}

Json_Exporter :: struct {
    pretty: bool,
}

Text_Exporter :: struct {
    uppercase: bool,
}

export_json :: proc(e: Json_Exporter, r: Report) -> string {
    if e.pretty {
        return fmt.aprintf(
            "{{\n  \"title\": \"%s\",\n  \"author\": \"%s\",\n  \"pages\": %d\n}}",
            r.title,
            r.author,
            r.pages,
        )
    }
    return fmt.aprintf(
        `{{"title": "%s", "author": "%s", "pages": %d}}`,
        r.title,
        r.author,
        r.pages,
    )
}

export_text :: proc(e: Text_Exporter, r: Report) -> string {
    if e.uppercase {
        upper := strings.to_upper(r.title)
        defer delete(upper)
        return fmt.aprintf("%s by %s (%d pages)", upper, r.author, r.pages)
    }
    return fmt.aprintf("%s by %s (%d pages)", r.title, r.author, r.pages)
}