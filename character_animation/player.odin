package main

ANIMATION_NAME :: enum {
    AIR_ATTACK,
    ATTACK,
    FALL,
    HIT,
    IDLE,
    JUMP, 
    RUN, 
    WALL,
}

Player :: struct {
    position: [2]f32,
    speed: i32,
    state: ANIMATION_NAME,
}