# Virus Vanquisher

A collaborative three-level TSA game about recognizing malware, built with Godot and GDScript. This maintenance revision repairs gameplay and adds engine checks. Original development history and assets are preserved.

## Run

Use **Godot 4.6.1 stable, standard edition**. Import `project.godot` and press **F5** to start the full game. The Compatibility renderer supports a broader range of desktop hardware. With Godot on PATH, run `godot --path .`; otherwise use its full executable path. On Windows, the `_console.exe` build shows diagnostic output. Playing requires no Python packages or external assets.

| Control | Action |
|---|---|
| Enter / Space / Start | Start the intro |
| Left / Right | Move |
| Up | Jump; press again for one midair jump |
| Space | Fire one shot per press |
| R | Reload after 0.8 seconds; firing is disabled during reload |
| Tap to Fight / Enter | Dismiss instructions |

Spam email reverses horizontal controls and temporarily changes jump to Down. Gift boxes spawn enemies; green shields slow movement. Water bottles restore ammo; orange shields grant invincibility; floppy disks clear minions. Movement uses a fixed ground height in a 288 by 162 game area, without a platform collision system.

Campaign: intro → Ransomware Rex → Trojan Titan → Worm King → victory → Play Again. Death restarts the current level. Initial landing includes a brief head rub; later jumps return directly to walking.

## Verify a fresh source copy

Python 3.12 or newer runs the standard-library validation wrapper:

```powershell
python scripts/validate_game.py --godot "C:/path/to/Godot_v4.6.1-stable_win64_console.exe"
```

It creates a temporary source copy without an imported cache, isolates engine settings, imports assets, parses every GDScript file and runs **26 gameplay checks plus 31 campaign checks**. It scans logs for script/runtime errors even when the engine returns zero. Logs, engine version and source fingerprints are saved in `.validation/`, which Git ignores. GitHub Actions runs headless checks with the pinned official Linux engine and release checksum after push.

Campaign checks use real scenes, signals, damage, worm splitting, pickups, victory, replay and death restart. They immobilize bosses and replenish ammo for deterministic transition checks. They do not establish human difficulty balance or replace a normal playthrough.

Optional rendered captures require a graphics-capable desktop:

```powershell
godot --path . --fixed-fps 60 --script res://tests/visual_capture.gd
```

Eight controlled scene captures are saved in `.validation/`.

## Maintenance changes

- Fixed player states, duplicate movement/fire handling, double-jump limits and sprite facing.
- Added reload so missed shots cannot permanently exhaust ammunition.
- Repaired projectile parsing, engulf damage ticks, enemy speed and projectile consumption.
- Used world coordinates for cross-container hits, chasing and spawns; bounds remain relative to the level.
- Added worm-minion contact damage and single-use collectible protection.
- Shared one instruction overlay; paused combat during instructions and after death/victory.
- Added engine tests, CI, run instructions and validation evidence.

Missing custom art still uses procedural drawings, and some sound slots contain silence. Complete audio, packaged exports and public releases are not claimed. See `docs/validation.md` and `docs/manual-playthrough.md`.

## Collaboration and attribution

This was a three-person TSA project. Original history records Sanvi Nethikunta's intro-scene work in commit `2fa233731e4a044aff5ab5dfc6482e3ea97d506e`, including TV effects, animation/transitions and initial assets/configuration. Later gameplay commits are attributed to collaborators. History may not capture all work done together; this repository does not attribute every system to one person. This repair is subsequent maintenance, separate from the original competition submission.
