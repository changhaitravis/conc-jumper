# TFC Conc & Rocket Jumping Platformer (Godot 4)

A first-person movement and jumping platformer prototype inspired by Team Fortress Classic (TFC) concussion grenade maps and rocket jumping.

## Running the game

Open `project.godot` in Godot 4.3 or newer and run the project — the main scene (`scenes/main_course.tscn`) starts automatically. No other setup is needed: the input map and physics settings ship with the project.

## Features
- **GoldSrc/Source Air Physics**: Quake/Source-style air acceleration, air-strafing, ground friction, and bunnyhopping.
- **TFC Concussion Grenades**: Handheld 4-second prime timer — cook one in hand and throw it on release, or let it detonate in hand for a hand-conc. Carry up to 4 at a time; checkpoints refill them.
- **Rocket Launcher**: Straight-line projectile with impact detonation for rocket jumps. Missed rockets fizzle out after 5 seconds instead of flying forever, and a fresh rocket can't collide with the player who fired it.
- **Platformer Flow**: Checkpoint trigger system, instant respawn at checkpoint on kill/fall zone, and conc refill at checkpoints.

## Controls

The input map is preconfigured in `project.godot` (Project Settings → Input Map):

| Action | Binding |
| --- | --- |
| Move | W / A / S / D |
| Jump | Space |
| Crouch | Ctrl or C |
| Prime conc (release to throw) | Right Mouse Button or E |
| Fire rocket | Left Mouse Button |
| Respawn at checkpoint | R |
| Toggle mouse capture | Esc |

The mouse is captured when the game starts. Press Esc to release it; while released, clicking re-captures the mouse instead of firing.

## Project settings

The project ships tuned for this movement model — no changes needed:

- **Physics ticks per second**: 66 (Project Settings → Physics → Common)
- **3D default gravity**: 24.0
