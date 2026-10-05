# TFC Conc & Rocket Jumping Platformer (Godot 4)

A first-person movement and jumping platformer prototype inspired by Team Fortress Classic (TFC) concussion grenade maps and rocket jumping.

## Features
- **GoldSrc/Source Air Physics**: Quake/Source-style air acceleration, air-strafing, ground friction, and bunnyhopping.
- **TFC Concussion Grenades**: Handheld 4-second prime timer (cook in hand, throw/drop, or hand-conc detonation), physics bouncing, and radial velocity impulses.
- **Rocket Launcher**: Straight-line projectile with impact detonation for rocket jumps.
- **Platformer Flow**: Checkpoint trigger system, instant respawn at checkpoint on kill/fall zone, and ammo reset.

## Input Setup
Configure the following in `Project Settings -> Input Map`:
- `move_forward`: W
- `move_backward`: S
- `move_left`: A
- `move_right`: D
- `jump`: Space
- `crouch`: Ctrl or C
- `prime_conc`: Mouse Right Button or E
- `fire_rocket`: Mouse Left Button
- `restart_checkpoint`: R

## Recommended Project Settings
- **Physics Ticks Per Second**: `66` or `100` (Project Settings -> Physics -> Common -> Physics Ticks Per Second).
