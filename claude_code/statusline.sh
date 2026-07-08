#!/bin/bash
# Claude Code statusline: identity/git/model line + context/cost/usage line.
# All data comes from Claude Code's stdin JSON or cheap local commands
# (git/whoami/hostname) - no network calls, no local cost accumulation.

input=$(cat)

# --- colors ---
RESET='\033[0m'
BBLUE='\033[1;34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
BWHITE='\033[1;37m'
BLUE='\033[34m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
GRAY='\033[90m'
PINK='\033[38;5;213m'
LGRAY='\033[38;5;250m'

color_for_pct() {
  # $1 = percentage (integer); prints a color code by 70/90 threshold
  local pct=$1
  if [ "$pct" -ge 90 ]; then echo "$RED"
  elif [ "$pct" -ge 70 ]; then echo "$YELLOW"
  else echo "$GREEN"; fi
}

fmt_k() {
  # $1 = raw token count; prints human-readable K/M size (no trailing ".0")
  local n=${1:-0}
  if [ "$n" -ge 1000000 ]; then
    printf '%sM' "$(awk -v n="$n" 'BEGIN{v=n/1000000; printf (v==int(v)) ? "%d" : "%.1f", v}')"
  elif [ "$n" -ge 1000 ]; then
    printf '%sK' "$(awk -v n="$n" 'BEGIN{v=n/1000; printf (v==int(v)) ? "%d" : "%.1f", v}')"
  else
    printf '%s' "$n"
  fi
}

# --- local system info (not present in stdin JSON) ---
USER_HOST="$(whoami)@$(hostname -s 2>/dev/null || hostname)"

# --- workspace / git (repo name prefers Claude Code's parsed value) ---
DIR=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
REPO=$(echo "$input" | jq -r '.workspace.repo.name // empty')
if [ -z "$REPO" ] && [ -n "$DIR" ]; then
  TOPLEVEL=$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$TOPLEVEL" ]; then
    REPO=$(basename "$TOPLEVEL")
  else
    REPO=$(basename "$DIR")
  fi
fi
BRANCH=""
[ -n "$DIR" ] && BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)

# --- model / effort / thinking ---
MODEL_NAME=$(echo "$input" | jq -r '.model.display_name // "?"')
MODEL_ID=$(echo "$input" | jq -r '.model.id // empty')
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')
THINKING=$(echo "$input" | jq -r 'if .thinking.enabled == true then "on" elif .thinking.enabled == false then "off" else empty end')

EFFORT_COLOR="$GREEN"
case "$EFFORT" in
  high) EFFORT_COLOR="$YELLOW" ;;
  xhigh|max) EFFORT_COLOR="$RED" ;;
esac

THINKING_COLOR="$LGRAY"
[ "$THINKING" = "on" ] && THINKING_COLOR="$PINK"

# --- context window ---
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0 | floor')
CTX_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
CTX_IN=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
CTX_OUT=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
CTX_USED=$((CTX_IN + CTX_OUT))
CTX_COLOR=$(color_for_pct "$CTX_PCT")

BAR_WIDTH=10
FILLED=$((CTX_PCT * BAR_WIDTH / 100))
[ "$FILLED" -gt "$BAR_WIDTH" ] && FILLED=$BAR_WIDTH
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /▓}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"

# --- session cost (computed by Claude Code, not accumulated here) ---
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
COST_FMT=$(printf '$%.3f' "$COST")

# --- account usage: Claude.ai subscription rate limits (5h/7d), fetched
#     live by Claude Code from Anthropic - this IS "the API", we just read it ---
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
SEVEN_D=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# --- build line 1: identity + git + model/effort/thinking ---
LINE1="${BBLUE}${USER_HOST}${RESET}"
if [ -n "$REPO" ]; then
  LINE1="${LINE1} · ${MAGENTA}📁 ${REPO}${RESET}"
fi
if [ -n "$BRANCH" ]; then
  LINE1="${LINE1} ${CYAN}🌿 ${BRANCH}${RESET}"
fi
LINE1="${LINE1} · ${BWHITE}🤖 ${MODEL_NAME}${MODEL_ID:+ (${MODEL_ID})}${RESET}"
if [ -n "$EFFORT" ]; then
  LINE1="${LINE1} · ${BLUE}effort:${EFFORT_COLOR}${EFFORT}${RESET}"
  if [ -n "$THINKING" ]; then
    LINE1="${LINE1} (${THINKING_COLOR}🧠${RESET})"
  fi
elif [ -n "$THINKING" ]; then
  LINE1="${LINE1} · (${THINKING_COLOR}🧠${RESET})"
fi

# --- build line 2: context bar + session cost + account usage ---
LINE2="${CTX_COLOR}[${BAR}] ${CTX_PCT}%${RESET} ctx (${CTX_COLOR}$(fmt_k "$CTX_USED")${RESET}/$(fmt_k "$CTX_SIZE")) · ${YELLOW}💰 ${COST_FMT}${RESET} session"

if [ -n "$FIVE_H" ]; then
  FIVE_H_INT=$(printf '%.0f' "$FIVE_H")
  FIVE_H_COLOR=$(color_for_pct "$FIVE_H_INT")
  FIVE_H_REM=$((100 - FIVE_H_INT))
  LINE2="${LINE2} · ${BLUE}5h ${FIVE_H_COLOR}${FIVE_H_INT}%${RESET}${BLUE}/${FIVE_H_REM}%${RESET}"
fi
if [ -n "$SEVEN_D" ]; then
  SEVEN_D_INT=$(printf '%.0f' "$SEVEN_D")
  SEVEN_D_COLOR=$(color_for_pct "$SEVEN_D_INT")
  SEVEN_D_REM=$((100 - SEVEN_D_INT))
  LINE2="${LINE2} · ${BLUE}7d ${SEVEN_D_COLOR}${SEVEN_D_INT}%${RESET}${BLUE}/${SEVEN_D_REM}%${RESET}"
fi

printf '%b\n%b\n' "$LINE1" "$LINE2"
