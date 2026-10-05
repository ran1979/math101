# Multiply Quest

**Play it:** https://ran1979.github.io/math101/

A browser game that teaches the multiplication table (1×1 to 10×10) to kids aged 9–12.
Every question is drawn as groups of objects (7 × 4 = 7 groups of 4 apples), so kids *see* why the answer is what it is.

Built with Godot 4.7 + GDScript, exported to HTML5. No backend and no account; progress is saved in the browser.

## Game modes

| Mode | What it does |
|------|--------------|
| **Play (Adventure)** | 4 worlds (Number Forest, Pirate Island, Space Station, Dragon Castle). Each has 4 levels and a boss. Finishing a level unlocks the next one. |
| **Practice** | Pick a table (×1 … ×10), or **Mix Everything**, which focuses on the facts you find tricky. No timer. |
| **Speed Challenge** | Optional 60-second round. Shows score, accuracy, best combo and facts to practice. |
| **Daily Challenge** | 10 questions, the same for everyone that day and new the next day. Earn up to 3 stars. |
| **My Progress** | Level and XP, stats, weakest facts, and a 10×10 mastery map (★★★ mastered, ★★ learning, ★ needs practice). |
| **Settings** | Turn music and sound effects on or off, change your hero, reset progress (asks you to tap twice). |

How each question works: the groups appear one by one. The player types an answer (keypad, or the keyboard with Enter).
- **Correct:** confetti, every object lights up, the groups are counted up, then XP, coins and combo are added.
- **Wrong:** a friendly "Let's figure it out!", the groups are counted out loud (4, 8, 12 … 28, with 4 + 4 + … = 28), then "7 × 4 = 28" is shown and the player tries again.

Each fact gets a mastery score from 0 to 4. 3×7 and 7×3 share one score. Weaker facts are picked more often.

## Run locally

Requirements: [Godot 4.7](https://godotengine.org/download) with **Web export templates** installed (Editor → Manage Export Templates), and `python3`.

```sh
./run.sh            # export the web build and serve it at http://localhost:8000 (opens the browser)
./run.sh 9000       # same, on another port
./run.sh --native   # run in a normal Godot window instead
GODOT=/path/to/godot ./run.sh   # if godot isn't on your PATH
```

Or open the folder in the Godot editor and press F5.

## Tests

```sh
godot --headless --path . -s tests/run_tests.gd        # unit tests: factor bounds, mastery, adaptive picking, XP, daily seed, save/load
godot --headless --path . res://tests/FlowTest.tscn    # end-to-end: plays every mode to its results screen
```

## Deploy (GitHub Pages)

Every push to `main` runs `.github/workflows/pages.yml`, which:
1. downloads Godot 4.7.2 and its web export templates (cached between runs),
2. runs both test suites,
3. exports the web build and publishes it to GitHub Pages.

One-time setup: **Settings → Pages → Source: GitHub Actions**.
The export is single-threaded, so it runs on any static host. Pages doesn't need COOP/COEP headers.

## Project layout

```
project.godot, export_presets.cfg   engine config + "Web" export preset
run.sh                              local build & serve
scenes/                             MainMenu, Adventure, Practice, Quiz, Progress, Settings
scripts/
  save_manager.gd      (autoload Save)       ConfigFile in user:// (IndexedDB in the browser)
  question_manager.gd  (autoload Questions)  question generation, mastery, adaptive selection, daily seed
  game_manager.gd      (autoload Game)       worlds, sessions, scene changes, rewards bookkeeping, theme
  audio_manager.gd     (autoload Audio)      all sounds and music synthesized in code
  reward_manager.gd                          XP / levels / stars / combo rules (pure functions)
  screens/                                   one script per scene; quiz.gd runs every mode
ui/components/
  ui.gd                design system: buttons, cards, labels, bars
  visualizer.gd        MultiplicationVisualizer: show_groups, animate_counting, highlight_all, show_solution, reset
  keypad.gd, art.gd, art_icon.gd, backdrop.gd
tests/                                       unit + end-to-end tests (left out of the export)
```

All art and audio are generated in code, so there are no asset files. To use real assets, swap them into `Art.draw()` or `Audio.sounds`.
Per-fact stats (attempts, correct, wrong, time) and daily history are already saved, so a parent dashboard could be added later.
