# From terminal games to a 3D game

In a terminal game, you often own a loop: read input, update state, print the
result. Godot owns that loop. Your scripts respond to input and update nodes.

## Read the project in this order

1. **`scenes/main.tscn`** is the entry scene. A scene is a reusable tree of nodes.
   Here it contains a single Node3D with the game script attached.
2. **`scripts/game.gd`** is the coordinator. `_ready()` builds the level and GUI.
   It owns mission state and connects player, guards, and objectives.
3. **`scripts/player.gd`** is the controller. `_physics_process(delta)` updates
   movement at a fixed physics rate. `move_and_slide()` resolves collisions.
   Mouse motion rotates the body horizontally and the camera vertically.
4. **`scripts/guard.gd`** is the opponent behavior. It raycasts to check sight,
   follows an A* grid around obstacles, and telegraphs an attack. A brief memory
   lets it follow the last seen position without knowing the player forever.
5. **`scripts/world.gd`** builds primitive level geometry. **`shapes.gd`** keeps
   repeated mesh/material creation out of the mission code.
6. **`scripts/hud.gd`** creates native GUI controls. CanvasLayer draws the HUD
   separately from the 3D camera. Containers manage menu spacing.

The level is generated in code to keep the initial contribution small and
self-contained. The editor scene tree will look sparse before running.
During play, use the editor's **Remote** scene tree to inspect generated nodes.
Later, move authored rooms and characters into their own `.tscn` scenes so
level design can happen visually in the editor.

## A shot, step by step

The player checks the cooldown and magazine, casts a ray from the camera,
and finds the first solid object. A guard hit receives damage. A wall stops
the shot. A short tracer and particles communicate the result. These are
arcade rules; the prototype does not simulate real ballistics.

## First small learning exercises

- Change `SPEED` in `player.gd`, run, and feel the difference.
- Change one sign in `world.gd` and inspect it in the level.
- Change a guard's bark in `guard.gd` and test readability during a chase.
- Move a desk and verify that guards still find a route around it.

Make one change at a time. Keep the game playable after each change.

## Official references

- [Your first 3D game](https://docs.godotengine.org/en/stable/getting_started/first_3d_game/index.html)
- [Nodes and scenes](https://docs.godotengine.org/en/stable/getting_started/step_by_step/nodes_and_scenes.html)
- [CharacterBody3D](https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html)
- [Ray casting](https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html)
