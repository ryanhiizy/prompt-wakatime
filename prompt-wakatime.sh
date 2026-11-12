#!/bin/sh
# One WakaTime heartbeat per prompt typed in Claude Code or the Codex app.
# Forks and returns immediately. The host is identified from the parent
# process, since env vars like CLAUDECODE leak into nested agents.
# The parent is read before forking: a hook's `sh -c` wrapper (Linux) exits
# as soon as this script returns.
info=$(ps -o ppid=,command= -p "$PPID")
(
  for _ in 1 2 3; do
    info=${info#"${info%%[! ]*}"} # trim leading spaces
    [ -n "$info" ] || exit
    cmd=${info#* }
    case $cmd in
      sh\ -c\ *|*/sh\ -c\ *|bash\ -c\ *|*/bash\ -c\ *|zsh\ -c\ *|*/zsh\ -c\ *)
        info=$(ps -o ppid=,command= -p "${info%% *}"); continue ;; # hook shell wrapper
      *.app/Contents/*codex*app-server*) app=Codex editor=codex model=gpt/5 ;;
      *" -p "*|*" -p"|*--print*) ;; # claude -p (scripted / agents)
      claude|claude\ *|*/claude|*/claude\ *|*/claude/versions/*|*/.claude/remote/ccd-cli/*) app="Claude Code" editor=claude-code model=claude/5 ;;
    esac
    break # anything else (codex exec, codex CLI, IDEs) is skipped
  done
  [ -n "$app" ] || exit
  cfg=${WAKATIME_HOME:-$HOME}/.wakatime.cfg
  key=$(sed -n 's/^[[:space:]]*api_key[[:space:]]*=[[:space:]]*//p' "$cfg" | head -n 1)
  [ -n "$key" ] || exit
  url=$(sed -n 's/^[[:space:]]*api_url[[:space:]]*=[[:space:]]*//p' "$cfg" | head -n 1)
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$PWD
  host=$(scutil --get LocalHostName 2>/dev/null) || host=$(hostname)
  exec curl -s -m 10 -o /dev/null -u "$key:" \
    -A "wakatime/v1.0.0 ($(uname -s | tr A-Z a-z)) sh $model $editor/1.0.0 $editor-wakatime/0.3.3" \
    -H "X-Machine-Name: $host" \
    -H 'Content-Type: application/json' \
    -d "{\"entity\":\"$app\",\"type\":\"app\",\"category\":\"ai coding\",\"project\":\"${root##*/}\",\"time\":$(date +%s)}" \
    "${url:-https://api.wakatime.com/api/v1}/users/current/heartbeats"
) </dev/null >/dev/null 2>&1 &
