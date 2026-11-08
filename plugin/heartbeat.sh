#!/bin/sh
# One WakaTime heartbeat per prompt typed in Claude Code or the Codex app.
# Forks and returns immediately. The host is identified from the parent
# process, since env vars like CLAUDECODE leak into nested agents.
(
  p=$PPID
  for _ in 1 2 3; do
    cmd=$(ps -o command= -p "$p") || exit
    case $cmd in
      sh\ -c\ *|*/sh\ -c\ *|bash\ -c\ *|*/bash\ -c\ *|zsh\ -c\ *|*/zsh\ -c\ *)
        p=$(ps -o ppid= -p "$p"); continue ;; # hook shell wrapper
      *.app/Contents/*codex*app-server*) app=Codex editor=codex ;;
      *" -p "*|*" -p"|*--print*) ;; # claude -p (scripted / agents)
      claude|claude\ *|*/claude|*/claude\ *) app="Claude Code" editor=claude-code ;;
    esac
    break # anything else (codex exec, codex CLI, IDEs) is skipped
  done
  [ -n "$app" ] || exit
  cli=${WAKATIME_CLI:-$HOME/.wakatime/wakatime-cli}
  [ -x "$cli" ] || cli=$(command -v wakatime-cli) || exit
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$PWD
  exec "$cli" --entity "$app" --entity-type app --category "ai coding" \
    --project "${root##*/}" --plugin "$editor/1.0.0 prompt-wakatime/0.1.0" --sync-ai-disabled
) </dev/null >/dev/null 2>&1 &
