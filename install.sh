#!/bin/sh
# Installs ~/.wakatime/prompt-wakatime.sh and adds it as a UserPromptSubmit
# hook in ~/.claude/settings.json and ~/.codex/hooks.json. Safe to re-run.
set -e
dest="$HOME/.wakatime/prompt-wakatime.sh"
mkdir -p "$HOME/.wakatime"
src="$(dirname "$0")/prompt-wakatime.sh"
case $0 in
  *install.sh) [ -f "$src" ] && cp "$src" "$dest" ;;
  *) curl -fsSL https://raw.githubusercontent.com/ryanhiizy/prompt-wakatime/main/prompt-wakatime.sh -o "$dest" ;;
esac
chmod +x "$dest"
python3 -I - "\"$dest\"" <<'EOF'
import json, os, sys
cmd = sys.argv[1]
for path in ("~/.claude/settings.json", "~/.codex/hooks.json"):
    path = os.path.expanduser(path)
    if not os.path.isdir(os.path.dirname(path)):
        continue
    try:
        with open(path) as f:
            cfg = json.load(f)
    except FileNotFoundError:
        cfg = {}
    groups = cfg.setdefault("hooks", {}).setdefault("UserPromptSubmit", [])
    if any(h.get("command") == cmd for g in groups for h in g.get("hooks", [])):
        print("already installed:", path)
        continue
    groups.append({"hooks": [{"type": "command", "command": cmd, "timeout": 5}]})
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
    print("added hook:", path)
EOF
echo "Done. Codex asks you to trust the new hook once; open Claude sessions may need /hooks or a restart."
