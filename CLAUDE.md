# Naksat Saga

Godot 4.7.2 GDScript game (web export, no threads). The owner does not code: explain in plain Thai, keep code comments in Thai.

- Scenes are built in code; `main.tscn` only attaches `main.gd`.
- Art: Gemini pixel-art PNGs in `assets/art/` (single still frame per character, animated in code by `ChibiVisual`/enemy scripts; sprite files are 2x display size). New source images on green/magenta backgrounds go through `python3 tools/prep_art.py <src_dir> assets/art` (keys out the background, builds mirrored tiling backgrounds). Vector `_draw()` art remains as fallback and for platforms, signs and effects.
- Animation: hero forms use frame-by-frame art in `assets/art/frames/hero_<form>_<pose>_<n>.png` (idle, walk x4, attack x3, jump, fall, land), cut from Gemini sprite sheets with `python3 tools/prep_frames.py <src_dir> assets/art/frames` (sheets named `naksat_hero_<form>_{walk,attack,poses}.png`; generated in the user's Gemini chat "Chibi Boy Hero Sprite Creation"). Monsters and the boss use frames too (`frog_*`, `mushroom_*`, `tiger_boss_*`, cut with `tools/prep_monsters.py`, source art faces LEFT). `ChibiVisual` picks frames; `chibi_rig.gd` (cut-out puppet) is only a fallback when a form has no frames; effects live in `entities/effects/fx.gd`; `Game.shake()` / `Game.hit_stop()` for impact. Check poses with `xvfb-run godot --path . res://tests/showcase.tscn -- shots=<dir>`.
- Backgrounds: village and field use 3 parallax layers (`layer_far.png`, `layer_<style>_mid.png`, `layer_<style>_near.png`, cut with `tools/prep_layers.py`) plus the road strip `ground_<style>.png`; the cave uses the single `bg_cave.png`.
- Systems in `utilities/game.gd`: level/EXP (`add_exp`, +15 max HP and +10% attack per level), money, items (`ITEMS`, `REWARDS` drop tables), potions (F), bag (B, in the HUD). Drops are `entities/pickups/pickup.gd`. Auntie sells potions, Uncle buys materials (`stages/village.gd`).
- Add a hero form = one entry in `utilities/forms.gd` (same body size for all forms, outfit only). Skill kinds: melee / dash / aoe.
- Add a map = new script extending `Stage` in `stages/`, registered in `main.gd` STAGES.
- Combat uses rect checks via `Game.hit_enemies()`; enemies are in group `enemies` with `is_alive()`, `get_hurt_rect()`, `take_hit()`.
- Layers: 1 ground, 2 player, 4 enemies, 8 one-way platforms. Ground is y=600.
- Thai text: add spaces at phrase breaks so labels can wrap.
- Verify before pushing: `godot --headless --path . --import && godot --headless --path . res://tests/smoke.tscn` (must print RESULT: PASS). Screenshots: run under `xvfb-run` with `-- shots=<dir>`.
- Pushing to `main` runs `.github/workflows/deploy.yml`, which publishes the web build to the `gh-pages` branch.
