#!/bin/sh
# One WakaTime heartbeat per prompt typed in Claude Code or the Codex app.
# Forks and returns immediately. The host is identified from the parent
# process, since env vars like CLAUDECODE leak into nested agents.
# The parent and the hook input are read before forking: a hook's `sh -c`
# wrapper (Linux) exits as soon as this script returns, and dash gives a
# background job an empty stdin even with an explicit redirect.
info=$(ps -o ppid=,command= -p "$PPID")
input=$(head -c 4096)
(
  # Injected turns (task notifications, CI and session events, command output)
  # start with a tag; Codex has nothing else to tell them apart by.
  case $input in
    *'"prompt":"<'*) exit ;;
    *'"prompt":"This session is being continued from a previous conversation'*) exit ;; # compaction
    *'"prompt":"Another Claude session sent a message'*) exit ;; # message from another session
  esac
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
  if [ "$editor" = claude-code ]; then
    # Claude Code records who started each turn. Messages from other sessions,
    # agents and the app look like typed text, so count only turns it marks as
    # typed by you. The entry may land just after the hook fires: retry briefly.
    tp=$(printf %s "$input" | sed -n 's/.*"transcript_path":"\([^"]*\)".*/\1/p')
    snip=$(printf %s "$input" | sed -n 's/.*"prompt":"\(.\{1,80\}\).*/\1/p')
    [ -f "$tp" ] && [ -n "$snip" ] || exit
    for _ in 1 2 3 4 5 6; do
      line=$(tail -c 131072 "$tp" | grep -F -e '"type":"user"' -e '"operation":"enqueue"' | grep -v toolUseResult |
        grep -F -e "\"content\":\"$snip" -e "\"text\":\"$snip" | tail -n 1)
      case $line in *'"type":"user"'*) break ;; esac
      sleep 1
    done
    case $line in
      *'"turnOrigin":"human"'*) ;;
      *'"operation":"enqueue"'*) ;; # typed while a turn was running: written to the transcript later
      *) exit ;;
    esac
  fi
  cfg=${WAKATIME_HOME:-$HOME}/.wakatime.cfg
  key=$(sed -n 's/^[[:space:]]*api_key[[:space:]]*=[[:space:]]*//p' "$cfg" | head -n 1)
  [ -n "$key" ] || exit
  url=$(sed -n 's/^[[:space:]]*api_url[[:space:]]*=[[:space:]]*//p' "$cfg" | head -n 1)
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$PWD
  host=$(scutil --get LocalHostName 2>/dev/null) || host=$(hostname)
  set -- $(uname -srm) # os, kernel release, arch: WakaTime reads WSL from the release
  case $1 in Darwin) os=darwin ;; Linux) os=linux ;; *) os=$1 ;; esac
  exec curl -s -m 10 -o /dev/null -u "$key:" \
    -A "wakatime/v1.0.0 ($os-$2-$3) sh $model $editor/1.0.0 $editor-wakatime/0.3.4" \
    -H "X-Machine-Name: $host" \
    -H 'Content-Type: application/json' \
    -d "{\"entity\":\"$app\",\"type\":\"app\",\"category\":\"ai coding\",\"project\":\"${root##*/}\",\"time\":$(date +%s)}" \
    "${url:-https://api.wakatime.com/api/v1}/users/current/heartbeats"
) >/dev/null 2>&1 &
