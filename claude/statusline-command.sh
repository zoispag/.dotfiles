#!/bin/bash
# Claude Code statusLine
# Single line, truecolor (24-bit RGB):
#   {repo} | leaf+branch | 🧠 context 5-block bar+emoji+% | label+5-block bar+emoji+%left (🕐=5h, 🗓️=7d, 🧚=Fable) | cost | velocity | model
# Context bar fill = % used (no "used" word shown, just the number). The 3 limit bars' fill = % left (with "left" shown).
# Colors/emoji for all 4 meters are still driven by usage severity (danger), regardless of which % is displayed.
# "Fable" = the model-scoped weekly quota (the "Fable" row in /usage and claude.ai/settings/usage).
#  Claude Code's statusLine payload does not forward it, so the script queries the same OAuth usage
#  endpoint the /usage popup uses, with the keychain token Claude Code already stores, and caches the
#  result for USAGE_CACHE_TTL seconds. Falls back to payload fields; omitted if nothing is available.
# Colors are intentionally vivid (not dimmed) per explicit user color spec.

input=$(cat)
target_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
repo=$(echo "$input" | jq -r '.workspace.repo.name // empty')

cd "$target_dir" 2>/dev/null || true

# --- fallback repo name from directory if not provided ---
if [ -z "$repo" ]; then
  repo_dir=$(echo "$input" | jq -r '.workspace.project_dir // .cwd // .workspace.current_dir // empty'); [ -z "$repo_dir" ] && repo_dir=$(git -C "$target_dir" rev-parse --show-toplevel 2>/dev/null); repo=$(basename "${repo_dir:-$target_dir}")
fi

# --- git branch (skip optional locks) ---
branch=""
if git --no-optional-locks rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  branch=$(git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  if [ -z "$branch" ]; then
    branch=$(git --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  fi
fi

# --- palette (24-bit truecolor escape builders) ---
RESET="\033[0m"
BOLD_YELLOW="\033[1;38;2;255;215;0m"     # repo name
BOLD_CYAN="\033[1;38;2;0;220;220m"       # leaf + branch
PIPE="\033[2;38;2;100;100;100m|${RESET}" # dim gray separator
COST_YELLOW="\033[38;2;255;215;0m"
GREEN_ADD="\033[38;2;0;200;80m"
RED_DEL="\033[38;2;220;40;20m"
MAGENTA_MODEL="\033[38;2;255;90;230m"
GRAY_EMPTY="\033[38;2;60;60;60m"

# --- gradient color for a 0-100 position: green(0,200,80) -> yellow(220,200,0) -> red(220,40,20) ---
gradient_color() {
  local p=$1 r g b p2
  if [ "$p" -le 50 ]; then
    r=$(( 220 * p / 50 ))
    g=200
    b=$(( 80 - (80 * p / 50) ))
  else
    p2=$(( p - 50 ))
    r=220
    g=$(( 200 - (160 * p2 / 50) ))
    b=$(( 20 * p2 / 50 ))
  fi
  echo "$r $g $b"
}

# --- stepped usage-level color (for rate-limit / usage percentages) ---
level_color() {
  local p=$1 r g b
  if [ "$p" -lt 20 ]; then
    r=0; g=200; b=80
  elif [ "$p" -lt 70 ]; then
    r=220; g=200; b=0
  elif [ "$p" -lt 90 ]; then
    r=230; g=120; b=20
  else
    r=220; g=40; b=20
  fi
  echo "$r $g $b"
}

# --- dynamic emoji by usage severity (0-100) ---
emoji_for() {
  local p=$1
  if [ "$p" -lt 20 ]; then
    echo "\xf0\x9f\x9f\xa2"        # 🟢
  elif [ "$p" -lt 70 ]; then
    echo "\xe2\x9a\xa1"            # ⚡
  elif [ "$p" -lt 90 ]; then
    echo "\xf0\x9f\x94\xa5"        # 🔥
  else
    echo "\xf0\x9f\x9a\xa8"        # 🚨
  fi
}

# --- gradient bar of N blocks; fill proportion reflects usage severity (0-100) ---
render_bar() {
  local pct=$1 length=$2 filled i p r g b bar
  filled=$(( (pct * length + 50) / 100 ))
  [ "$filled" -lt 0 ] && filled=0
  [ "$filled" -gt "$length" ] && filled=$length
  bar=""
  for i in $(seq 1 "$length"); do
    if [ "$i" -le "$filled" ]; then
      p=$(( i * 100 / length ))
      read -r r g b <<< "$(gradient_color "$p")"
      bar="${bar}\033[38;2;${r};${g};${b}m\xe2\x96\x88"
    else
      bar="${bar}${GRAY_EMPTY}\xe2\x96\x88"
    fi
  done
  bar="${bar}${RESET}"
  printf '%s' "$bar"
}

# --- context usage: 🧠 label + gradient bar, emoji, and "% used" (colored by usage severity) ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
context_segment=""
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  [ "$used_int" -lt 0 ] 2>/dev/null && used_int=0
  [ "$used_int" -gt 100 ] 2>/dev/null && used_int=100

  bar=$(render_bar "$used_int" 5)
  emoji=$(emoji_for "$used_int")
  read -r pr pg pb <<< "$(level_color "$used_int")"
  pct_color="\033[1;38;2;${pr};${pg};${pb}m"

  context_segment=$(printf "\xf0\x9f\xa7\xa0 %b %b %b%d%%%b" "$bar" "$emoji" "$pct_color" "$used_int" "$RESET")
fi

# --- rate-limit usage: gradient bar + emoji + "% left", for 5h, 7d, Fable (gateway spend limit) ---
rate_segment() {
  local label=$1 pct=$2 length=${3:-5}
  local used_int bar_pct left_int bar emoji r g b color
  [ -z "$pct" ] && return
  used_int=$(printf '%.0f' "$pct")
  bar_pct=$used_int
  [ "$bar_pct" -lt 0 ] 2>/dev/null && bar_pct=0
  [ "$bar_pct" -gt 100 ] 2>/dev/null && bar_pct=100
  left_int=$(( 100 - used_int ))
  [ "$left_int" -lt 0 ] && left_int=0

  bar=$(render_bar "$left_int" "$length")
  emoji=$(emoji_for "$bar_pct")
  read -r r g b <<< "$(level_color "$bar_pct")"
  color="\033[1;38;2;${r};${g};${b}m"

  printf "%b%b%b %b %b %b%d%% left%b" "$color" "$label" "$RESET" "$bar" "$emoji" "$color" "$left_int" "$RESET"
}

five_h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_d_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
fable_pct=$(echo "$input" | jq -r '.rate_limits.seven_day_fable.used_percentage // .rate_limits.seven_day_mythos.used_percentage // .rate_limits.seven_day_opus.used_percentage // .rate_limits.spend_limit.used_percentage // empty')

# --- Fable weekly quota via the OAuth usage endpoint (cached) ---
USAGE_CACHE="$HOME/.claude/cache/statusline-usage.json"
USAGE_CACHE_TTL=${USAGE_CACHE_TTL:-60}
fetch_usage_cached() {
  local now mtime age token
  now=$(date +%s)
  if [ -f "$USAGE_CACHE" ]; then
    mtime=$(stat -f %m "$USAGE_CACHE" 2>/dev/null || stat -c %Y "$USAGE_CACHE" 2>/dev/null || echo 0)
    age=$(( now - mtime ))
    [ "$age" -lt "$USAGE_CACHE_TTL" ] && { cat "$USAGE_CACHE"; return; }
  fi
  token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
  if [ -n "$token" ]; then
    local body
    body=$(curl -sS -m 3 https://api.anthropic.com/api/oauth/usage \
      -H "Authorization: Bearer $token" -H "anthropic-beta: oauth-2025-04-20" \
      -H "Content-Type: application/json" 2>/dev/null)
    if [ -n "$body" ] && echo "$body" | jq -e '.limits' >/dev/null 2>&1; then
      mkdir -p "$(dirname "$USAGE_CACHE")"
      printf '%s' "$body" > "$USAGE_CACHE"; chmod 600 "$USAGE_CACHE"
      echo "$body"; return
    fi
  fi
  # network/auth failure: serve stale cache if any, and bump mtime so we back off for one TTL
  [ -f "$USAGE_CACHE" ] && { touch "$USAGE_CACHE"; cat "$USAGE_CACHE"; }
}
if [ -z "$fable_pct" ]; then
  fable_pct=$(fetch_usage_cached | jq -r '
    [.limits[]? | select(.kind=="weekly_scoped" and ((.scope.model.display_name // "") | ascii_downcase)=="fable") | .percent][0] // empty' 2>/dev/null)
fi

five_h_segment=$(rate_segment "\xf0\x9f\x95\x90" "$five_h_pct")  # 🕐 stands in for "5h"
seven_d_segment=$(rate_segment "\xf0\x9f\x97\x93\xef\xb8\x8f" "$seven_d_pct")  # 🗓️ stands in for "7d"
fable_segment=$(rate_segment "\xf0\x9f\xa7\x9a" "$fable_pct")  # 🧚 fairy, stands in for "Fable"

# --- session cost ---
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
cost_segment=""
if [ -n "$cost" ]; then
  cost_segment=$(printf "%b\$%.2f%b" "$COST_YELLOW" "$cost" "$RESET")
fi

# --- code velocity (+added / -removed) ---
added=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
removed=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')
velocity_segment=""
if [ -n "$added" ] || [ -n "$removed" ]; then
  velocity_segment=$(printf "%b+%d%b/%b-%d%b" "$GREEN_ADD" "${added:-0}" "$RESET" "$RED_DEL" "${removed:-0}" "$RESET")
fi

# --- repo + branch + model segments ---
repo_segment=$(printf "%b%s%b" "$BOLD_YELLOW" "$repo" "$RESET")

branch_segment=""
if [ -n "$branch" ]; then
  branch_segment=$(printf "\xf0\x9f\x8c\xbf %b(%s)%b" "$BOLD_CYAN" "$branch" "$RESET")
fi

model_segment=$(printf "\xf0\x9f\xa4\x96 %b%s%b" "$MAGENTA_MODEL" "$model" "$RESET")

# --- assemble, skipping empty segments ---
segments=()
[ -n "$repo_segment" ] && segments+=("$repo_segment")
[ -n "$branch_segment" ] && segments+=("$branch_segment")
[ -n "$context_segment" ] && segments+=("$context_segment")
[ -n "$five_h_segment" ] && segments+=("$five_h_segment")
[ -n "$seven_d_segment" ] && segments+=("$seven_d_segment")
[ -n "$fable_segment" ] && segments+=("$fable_segment")
[ -n "$cost_segment" ] && segments+=("$cost_segment")
[ -n "$velocity_segment" ] && segments+=("$velocity_segment")
segments+=("$model_segment")

line=""
for i in "${!segments[@]}"; do
  if [ "$i" -eq 0 ]; then
    line="${segments[$i]}"
  else
    line=$(printf "%s %b %s" "$line" "$PIPE" "${segments[$i]}")
  fi
done

printf "%b\n" "$line"
