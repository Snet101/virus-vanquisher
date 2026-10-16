# Stage 5 validation — October 16, 2026

Baseline: `7a6a15d51db866b381f8a75de4679a0055bb2a92`. Branch: `codex/gameplay-repair`.

Validated engine: Godot `4.6.1.stable.official.14d19694e`, Windows x64. The clean-copy wrapper imports supplied assets, parses every GDScript file, then runs 26 gameplay assertions and 31 campaign assertions. The report and source fingerprints are saved as `.validation/verification.json`.

Gameplay checks exercise initial landing/rub/walking, movement speed, two-jump limit, one fire event, empty ammo, reload, damage/invincibility, slow/inverted controls, translated parent-container collisions, projectile consumption, enemy speed, engulf entry/interval/exit/reentry, single-use pickup and single-use intro dismissal. Campaign checks use real scenes and signals from Start through all three bosses, pickups, worm splits, victory, replay and death reload. Boss movement and ammo limits are overridden in that controlled integration test; this is not a normal difficulty playthrough.

Eight screenshots were rendered with the Compatibility/OpenGL renderer on AMD Radeon hardware: start screen and instruction/combat views of all three levels, plus victory. Inspection caught and repaired overflowing instruction text and button geometry. Layout assertions now enforce the description boundary. Captures do not verify audio, frame pacing on other hardware or complete game feel.

The initial sandboxed editor attempt could not write its normal settings directory. Final validation isolates settings inside the workspace. The wrapper scans logs for engine/script errors and leaked-instance diagnostics as well as checking exit codes. GitHub's Linux checks remain pending until push.

Original PNG/SVG assets and original Git history are preserved. Contribution claims distinguish collaborative original development from later maintenance. Human difficulty/audio playthrough and release exports remain pending; see manual-playthrough.md.

Primary reference: [Godot 4.6 command-line documentation](https://docs.godotengine.org/en/4.6/tutorials/editor/command_line_tutorial.html).
