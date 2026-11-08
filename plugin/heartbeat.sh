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
  cfg=${WAKATIME_HOME:-$HOME}/.wakatime.cfg
  key=$(sed -n 's/^[[:space:]]*api_key[[:space:]]*=[[:space:]]*//p' "$cfg" | head -n 1)
  [ -n "$key" ] || exit
  url=$(sed -n 's/^[[:space:]]*api_url[[:space:]]*=[[:space:]]*//p' "$cfg" | head -n 1)
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$PWD
  exec curl -s -m 10 -o /dev/null -u "$key:" \
    -A "wakatime/v1.0.0 ($(uname -s | tr A-Z a-z)) sh $editor/1.0.0 prompt-wakatime/0.2.0" \
    -H 'Content-Type: application/json' \
    -d "{\"entity\":\"$app\",\"type\":\"app\",\"category\":\"ai coding\",\"project\":\"${root##*/}\",\"time\":$(date +%s)}" \
    "${url:-https://api.wakatime.com/api/v1}/users/current/heartbeats"
) </dev/null >/dev/null 2>&1 &
