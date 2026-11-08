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
POST {api_url}/users/current/heartbeats
User-Agent: ... claude-code|codex/1.0.0 prompt-wakatime/0.2.0
{"entity":"Claude Code"|"Codex","type":"app","category":"ai coding","project":"<git root or cwd name>","time":<now>}
```

Don't run the official Claude Code or Codex WakaTime plugins alongside this one, or agent activity gets tracked again.
