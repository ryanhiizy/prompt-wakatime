# prompt-wakatime

Tracks **Claude Code** and **Codex** in WakaTime by prompts only. Each prompt you send fires one heartbeat (`UserPromptSubmit` hook) with the project name. No agent activity, no file tracking, no transcript parsing. The hook forks one `curl` to the WakaTime API and returns at once (~7ms).

Only prompts you type count. The hook checks its parent process:

| Host | Tracked |
| --- | --- |
| Codex app (ChatGPT.app `codex app-server`) | yes, as **Codex** |
| Claude Code desktop / interactive `claude` | yes, as **Claude Code** |
| `codex exec`, Codex CLI, IDE extensions | no |
| `claude -p` / `--print` | no |

So agents that shell out to `codex exec` or `claude -p` don't log time.

Needs only `curl` and an `api_key` in `~/.wakatime.cfg` (`api_url` is honoured too). No wakatime-cli: its "disable AI sync" mode drops `ai coding` heartbeats, and with sync on it parses transcripts and replaces them.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/ryanhiizy/prompt-wakatime/main/install.sh | sh
```

This copies `prompt-wakatime.sh` to `~/.wakatime/` and adds one `UserPromptSubmit` hook to `~/.claude/settings.json` and `~/.codex/hooks.json` (needs `python3` to edit the JSON). Codex asks you to trust the hook once. No plugins, no marketplace.

To uninstall, delete that hook entry from both files and remove `~/.wakatime/prompt-wakatime.sh`.

## What gets sent

```
POST {api_url}/users/current/heartbeats
User-Agent: ... claude/5 claude-code/1.0.0 claude-code-wakatime/0.3.3 | gpt/5 codex/1.0.0 codex-wakatime/0.3.3
X-Machine-Name: <Mac LocalHostName, else hostname>
{"entity":"Claude Code"|"Codex","type":"app","category":"ai coding","project":"<git root or cwd name>","time":<now>}
```

Don't run the official Claude Code or Codex WakaTime plugins alongside this one, or agent activity gets tracked again.
