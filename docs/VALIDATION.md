# Prototype validation

Tested with **Godot 4.6.2 stable** on a Linux runner.

- Editor import completed without script errors.
- Headless main-scene startup completed without runtime errors.
- The integration test passed with **0 failures**. It checks movement,
  pause immunity, damage, crouch, cover occlusion, shooting, ammo, reload,
  navigation paths, relay interaction, duplicate prevention, healing limits,
  uplink gating, victory, replay, defeat, and blood-off particles.

## Limits

These checks are not a full human playtest or a Windows performance benchmark.
Lighting, audio feel, controller comfort, and difficulty still need playtesting.
This build uses keyboard and mouse only, a fixed layout, primitive characters,
simple fall animations, and synthesized placeholder sound. The pursuit grid
handles static geometry; it is not crowd AI. There is no campaign save system.
Godot creates local settings in its normal user-data directory.

No Windows executable is included yet. Import `project.godot` to play.

## First manual pass on the target laptop

1. Check that the menu fits and the cursor is released on Esc and focus loss.
2. Verify aiming feels comfortable; adjust the sensitivity slider.
3. Walk, sprint, jump, and crouch behind a desk while a guard pursues.
4. Fire at a wall, then a guard; check feedback with blood on and off.
5. Complete all three relays, reach the uplink, and replay.
6. Let the player lose, restart, and check the state resets.
