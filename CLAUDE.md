# Naksat Saga

Godot 4.7.2 GDScript game (web export, no threads). The owner does not code: explain in plain Thai, keep code comments in Thai.

- Scenes are built in code; `main.tscn` only attaches `main.gd`. Art is placeholder `_draw()` code until real sprites arrive.
- Add a hero form = one entry in `utilities/forms.gd` (same body size for all forms, outfit only). Skill kinds: melee / dash / aoe.
- Add a map = new script extending `Stage` in `stages/`, registered in `main.gd` STAGES.
- Combat uses rect checks via `Game.hit_enemies()`; enemies are in group `enemies` with `is_alive()`, `get_hurt_rect()`, `take_hit()`.
- Layers: 1 ground, 2 player, 4 enemies, 8 one-way platforms. Ground is y=600.
- Thai text: add spaces at phrase breaks so labels can wrap.
- Verify before pushing: `godot --headless --path . --import && godot --headless --path . res://tests/smoke.tscn` (must print RESULT: PASS). Screenshots: run under `xvfb-run` with `-- shots=<dir>`.
- Pushing to `main` runs `.github/workflows/deploy.yml`, which publishes the web build to the `gh-pages` branch.
