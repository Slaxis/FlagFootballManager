# Audio assets

All audio mapped in `game/defs/audio.json`. See [LICENSES.md](./LICENSES.md) for
sources and licensing (everything here is CC0).

On first open, Godot scans this folder and auto-imports the files. If a file is
missing or unimported, the `Audio` autoload silently no-ops — the game still
runs without audio.

## Music loops (`audio/music/`) — `.ogg`

- `main_menu.ogg` — main menu screen
- `home_ambient.ogg` — player home (weekly planner)
- `drill_tense.ogg` — drill minigame tension
- `tryout_intense.ogg` — tryout overall
- `victory.ogg` — Ato 0 win screen
- `game_over.ogg` — game over screen

## SFX (`audio/sfx/`) — `.wav`

- `menu_click.wav` — any button press
- `menu_open.wav` / `menu_close.wav` — window/popup open & close
- `card_pick.wav` — selecting a card in the drill minigame
- `pass.wav` / `fail.wav` — drill situation result
- `week_advance.wav` — week finalized
- `collapse.wav` — vital hit 0 and triggered a binge
- `fridge_open.wav` / `phone_open.wav` — room item windows
