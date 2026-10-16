"""Import and test a fresh source copy with a pinned Godot, inspecting error logs."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True, help="Path to Godot 4.6.1 executable")
    args = parser.parse_args()
    executable = shutil.which(args.godot) or str(Path(args.godot).resolve())
    root = Path(__file__).resolve().parents[1]
    output = root / ".validation"
    output.mkdir(exist_ok=True)
    (output / ".gdignore").touch()
    env = os.environ.copy()
    for key in ["APPDATA", "LOCALAPPDATA", "XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME"]:
        env[key] = str(output / "user" / key.lower())
        Path(env[key]).mkdir(parents=True, exist_ok=True)
    version = subprocess.check_output([executable, "--version"], text=True, env=env).strip()
    if not version.startswith("4.6.1.stable"):
        raise RuntimeError(f"Expected Godot 4.6.1 stable, got {version}")
    hashes = {str(p.relative_to(root)).replace("\\", "/"): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in root.rglob("*") if p.is_file() and not any(v in p.parts for v in [".godot", ".git", ".validation"])}
    report = {"state": "incomplete", "engine": version, "source_sha256": hashes, "checks": []}
    def save():
        (output / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    save()
    try:
        with tempfile.TemporaryDirectory(prefix="game-clean-", dir=output) as temp:
            project = Path(temp) / "project"
            shutil.copytree(root, project, ignore=shutil.ignore_patterns(".git", ".godot", ".validation", "exports"))
            def run(name, arguments, expected=None):
                result = subprocess.run([executable, "--headless", "--path", str(project), *arguments],
                                        capture_output=True, text=True, encoding="utf-8", errors="replace", env=env, timeout=120)
                log = result.stdout + result.stderr
                (output / (name + ".log")).write_text(log, encoding="utf-8")
                if result.returncode or re.search(r"(?:SCRIPT ERROR:|ERROR:|instances leaked)", log):
                    raise RuntimeError(f"{name} failed; inspect .validation/{name}.log")
                if expected and expected not in log:
                    raise RuntimeError(f"{name} missing completion marker")
                report["checks"].append(name)
                save()
            run("import", ["--editor", "--import", "--quit"])
            for script in sorted(project.rglob("*.gd")):
                if ".godot" not in script.parts:
                    run("parse-" + script.stem, ["--script", "res://" + script.relative_to(project).as_posix(), "--check-only"])
            run("gameplay", ["--script", "res://tests/gameplay_tests.gd"], "26/26 gameplay checks")
            run("campaign", ["--fixed-fps", "60", "--script", "res://tests/campaign_tests.gd"], "31/31 campaign checks")
        report["state"] = "complete"
        save()
        print("PASS: clean import, all scripts parsed, 26 gameplay and 31 campaign checks")
    except Exception:
        report["state"] = "failed"
        save()
        raise


if __name__ == "__main__":
    main()
