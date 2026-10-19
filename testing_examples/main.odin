package main
import "core:mem"
import "core:fmt"

// export :: proc { export_json, export_text }

main :: proc() {
    tracking: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking)

    defer {
        fmt.printfln(
            "Current memory: %d bytes, peak memory: %d bytes",
            tracking.current_memory_allocated,
            tracking.peak_memory_allocated,
        )

        if len(tracking.allocation_map) > 0 {
            fmt.eprintln("Unfreed allocations:")

            for _, entry in tracking.allocation_map {
                fmt.eprintf(
                    "- %d bytes @ %v\n",
                    entry.size,
                    entry.location,
                )
            }
        }

        mem.tracking_allocator_destroy(&tracking)
    }

    report := Report{ title = "Systems Notes", author = "A. Lovelace", pages = 42 }

    // json_out := export(Json_Exporter{pretty = true}, report)
    json_out := export_json({pretty = true}, report)
    defer delete(json_out)

    // text_out := export(Text_Exporter{uppercase = true}, report)
    // defer delete(text_out)

    fmt.println(json_out)
    // fmt.println(text_out)
}