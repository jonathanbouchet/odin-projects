package main

import rl "vendor:raylib"
import "core:math"

Vec3 :: struct {
	x, y, z: f32,
}

Point2 :: struct {
	x, y: f32,
}

window_width  :: 600
window_height :: 600
default_size  :: 10

default_color :: rl.GREEN

vals := [8]Vec3{
	{-0.25,  0.25,  0.25},
	{-0.25, -0.25,  0.25},
	{ 0.25,  0.25,  0.25},
	{ 0.25, -0.25,  0.25},
	{-0.25,  0.25, -0.25},
	{-0.25, -0.25, -0.25},
	{ 0.25,  0.25, -0.25},
	{ 0.25, -0.25, -0.25},
}

// Fixed-size paths avoid dynamically sized nested slices.
edge_paths := [6][5]int{
	{0, 1, 3, 2, 0},
	{4, 5, 7, 6, 4},
	{0, 4, 0, 0, 0},
	{2, 6, 0, 0, 0},
	{1, 5, 0, 0, 0},
	{3, 7, 0, 0, 0},
}

edge_path_lengths := [6]int{5, 5, 2, 2, 2, 2}

project :: proc(x, y, z: f32) -> Point2 {
	// The supplied model and dz keep z nonzero. If you later animate
	// translation, guard against z approaching zero here.
	projected_x := x / z
	projected_y := y / z

	screen_x := (projected_x + 1) * 0.5 * f32(window_width) -
		f32(default_size) * 0.5
	screen_y := (1 - (projected_y + 1) * 0.5) * f32(window_height) -
		f32(default_size) * 0.5

	return {screen_x, screen_y}
}

transform_vertex :: proc(v: Vec3, dz, da: f32) -> Point2 {
	c := f32(math.cos(f64(da)))
	s := f32(math.sin(f64(da)))

	// Rotate in the xz plane, then translate along z.
	x := v.x*c - v.z*s
	y := v.y
	z := v.x*s + v.z*c + dz

	return project(x, y, z)
}

draw_vertices :: proc(points: [8]Point2) {
	size := f32(default_size)
	for p in points {
		rl.DrawRectangleV(
			{f32(int(p.x)), f32(int(p.y))},
			{size, size},
			default_color,
		)
	}
}

draw_lines :: proc(points: [8]Point2) {
	half_size := f32(default_size) * 0.5

	for path_index in 0..<len(edge_paths) {
		path := edge_paths[path_index]
		path_length := edge_path_lengths[path_index]

		for i in 0..<path_length-1 {
			p0 := points[path[i]]
			p1 := points[path[i+1]]

			rl.DrawLine(
				i32(p0.x + half_size),
				i32(p0.y + half_size),
				i32(p1.x + half_size),
				i32(p1.y + half_size),
				default_color,
			)
		}
	}
}

main :: proc() {
	rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT, .WINDOW_HIGHDPI})
	rl.InitWindow(window_width, window_height, "test")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	dz: f32 = 1
	da: f32 = 0
	active_ptr: i32 = 0
	slider_value: f32 = 3.14

	for !rl.WindowShouldClose() {
		rl.GuiToggleGroup(
			{20, 20, 100, 20},
			"vertices;lines;both",
			&active_ptr,
		)
		rl.GuiSlider(
			{20, 40, 100, 20},
			"0",
			"2pi",
			&slider_value,
			0,
			6.28,
		)

		da += slider_value * rl.GetFrameTime()

		// Project each vertex only once, then reuse it for drawing.
		points: [8]Point2
		for v, i in vals {
			points[i] = transform_vertex(v, dz, da)
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		switch active_ptr {
		case 0:
			draw_vertices(points)
		case 1:
			draw_lines(points)
		case:
			draw_lines(points)
			draw_vertices(points)
		}

		rl.DrawFPS(20, 0)
		rl.EndDrawing()
	}
}
