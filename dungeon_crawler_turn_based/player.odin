package main

import rl "vendor:raylib"

Player :: struct {
	grid_pos:    [2]int,
	facing:      int, // 0..3
	visual_pos:  rl.Vector3,
	visual_yaw:  f32,
	target_yaw:  f32,
	eye_height:  f32,
}