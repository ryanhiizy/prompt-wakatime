# prompt-wakatime

Tracks **Claude Code** and **Codex** in WakaTime by prompts only. Each prompt you send fires one heartbeat (`UserPromptSubmit` hook) with the project name. No agent activity, no file tracking, no transcript parsing (`--sync-ai-disabled`). The hook forks `wakatime-cli` and returns at once.

Only prompts you type count. The hook checks its parent process:

| Host | Tracked |
| --- | --- |
| Codex app (ChatGPT.app `codex app-server`) | yes, as **Codex** |
| Claude Code desktop / interactive `claude` | yes, as **Claude Code** |
| `codex exec`, Codex CLI, IDE extensions | no |
| `claude -p` / `--print` | no |

So agents that shell out to `codex exec` or `claude -p` don't log time.

Needs [wakatime-cli](https://github.com/wakatime/wakatime-cli) (`~/.wakatime/wakatime-cli` or on `PATH`, e.g. `brew install wakatime-cli`) and an `api_key` in `~/.wakatime.cfg`.

## Install

Claude Code:

```sh
claude plugin marketplace add ryanhiizy/prompt-wakatime
claude plugin install prompt-wakatime@prompt-wakatime
```

Codex (approve the hook when Codex asks you to trust it):

```sh
codex plugin marketplace add ryanhiizy/prompt-wakatime
codex plugin add prompt-wakatime@prompt-wakatime
```

## What gets sent

```
wakatime-cli --entity "Claude Code"|Codex --entity-type app --category "ai coding" \
  --project <git root or cwd name> --plugin "claude-code|codex/1.0.0 prompt-wakatime/0.1.0" --sync-ai-disabled
```

Don't run the official Claude Code or Codex WakaTime plugins alongside this one, or agent activity gets tracked again.
