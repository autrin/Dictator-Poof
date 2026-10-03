# Dictator Poof

**Outrun the bureaucracy. Break the blackout.**

An open-source, darkly comic 3D resistance game built with Godot and GDScript.
This is an early playable prototype, not a finished game: original block-shaped
art, simple synthesized sound, and one compact level.

## Play on Windows

1. Download **Godot 4.6.2 or newer, standard Windows x86_64 edition** from
   [godotengine.org](https://godotengine.org/download/windows/). No .NET SDK is needed.
2. Download this branch using GitHub's **Code → Download ZIP**, then extract it.
3. Launch Godot, choose **Import**, and select the extracted `project.godot`.
4. Let the initial import finish. Press **F6** with `scenes/main.tscn` open,
   or **F5** to run the project. Click **CLOCK IN. CAUSE PROBLEMS.**

An RTX 4070 laptop with 32 GB RAM is suitable for developing this prototype.
The project starts at 1280 × 720 using the Compatibility renderer. If Windows
selects the integrated GPU, choose the high-performance GPU for Godot in
Windows Settings → System → Display → Graphics. Performance has not yet been
measured on the target laptop. Start with the editor; no export is necessary.

## First mission: Department of No

Navigate an after-hours censorship office, evade or fight three oversized
fictional guards, and restore three amber relay terminals. Then reach the
uplink at the far end and broadcast. Each relay restores up to 25 health.

Guards pursue you around obstacles, briefly remember your last visible
position, and fire slowly while they can see you. Their visors brighten before
an attack. Crouch behind the desks to break their line of sight. Ammunition has
an unlimited reserve, but each 12-shot magazine needs reloading.

| Control | Action |
| --- | --- |
| WASD / mouse | Move / look |
| Left mouse button | Fire |
| R | Reload |
| Shift | Sprint |
| Ctrl | Crouch |
| Space | Jump |
| E | Use nearby terminal while looking at it |
| Esc | Pause / resume |

The menu includes blood and sound toggles and mouse sensitivity. Preferences
are saved locally. Blood uses small stylized particles, with no dismemberment.
Defeated guards fall and stay in the level. Focus loss pauses the mission.

## What exists today

- First-person movement, collisions, sprinting, crouching, and a flashlight.
- Raycast combat, reloads, hit feedback, health, and fallen enemies.
- Three fictional pursuers with exaggerated running and bureaucratic one-liners.
- A navigable office, three relay objectives, and a final uplink.
- Title, pause, victory, defeat, and replay interfaces.
- A headless integration test covering the main gameplay loop.

## What is still a concept

Additional levels, named fictional bosses, authored narrative scenes, voice
acting, original character models, a liberated-city hub, bars, relationships,
Persian localization, save games, and a Windows executable release are not
implemented. There are no real-person likenesses in this prototype.

## Learn and contribute

- [How the code works](docs/LEARNING.md)
- [Creative direction and next milestones](docs/DESIGN.md)
- [Research notes and source links](docs/RESEARCH.md)
- [Contribution guide](CONTRIBUTING.md)
- [Validation and known limitations](docs/VALIDATION.md)

## Run the checks

With Godot available as `godot` on your PATH:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/smoke.gd
```

The test exits with a nonzero status if a check fails. It does not replace
manual playtesting, visual review, or testing on the target Windows laptop.

## License

Original code, procedural geometry, and generated tones in this repository
are under the [MIT license](LICENSE). Godot is a separate MIT-licensed dependency;
see [Godot license and third-party notices](https://godotengine.org/license/).
Research articles are linked for reference and remain under their own licenses.
There are no downloaded models, photos, voices, fonts, or music in this prototype.
