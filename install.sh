#!/usr/bin/env bash
# Point Kilo, OpenCode, Kimi Code, Codex and/or Claude Code at the 0G Router.
#   curl -fsSL https://raw.githubusercontent.com/Ransom070400/0g-cli-setup/main/install.sh | bash
# Asks which tools to set up, then for your API key.
# Non-interactive: ZEROG_API_KEY=sk-... bash install.sh --tools kilo,codex   (or --tools all)
# Safe to re-run: it replaces its own blocks and backs up every file it touches.
set -euo pipefail

API="https://router-api.0g.ai"
REPO="https://github.com/Ransom070400/0g-cli-setup"
STAMP="$(date +%Y%m%d-%H%M%S)"

# --- look & feel -------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  B=$'\033[1m' D=$'\033[2m' R=$'\033[0m'
  P1=$'\033[38;5;135m' P2=$'\033[38;5;141m' P3=$'\033[38;5;177m'
  GRN=$'\033[38;5;84m' YEL=$'\033[38;5;221m' RED=$'\033[38;5;203m' CYN=$'\033[38;5;117m'
  FANCY=1
else
  B="" D="" R="" P1="" P2="" P3="" GRN="" YEL="" RED="" CYN=""; FANCY=0
fi

STEP=0; STEPS=3
step() { STEP=$((STEP+1)); printf '\n%s%s[%d/%d]%s %s%s%s\n' "$P2" "$B" "$STEP" "$STEPS" "$R" "$B" "$*" "$R"; }
ok()   { printf '  %s✓%s %s\n' "$GRN" "$R" "$*"; }
warn() { printf '  %s!%s %s\n' "$YEL" "$R" "$*"; }
info() { printf '  %s%s%s\n' "$D" "$*" "$R"; }
die()  { printf '\n  %s✗ %s%s\n\n' "$RED" "$*" "$R" >&2; exit 1; }
sub()  { printf '\n  %s%s%s\n' "$CYN" "$*" "$R"; }

short()  { case "$1" in "$HOME"/*) printf '~/%s' "${1#"$HOME"/}" ;; *) printf '%s' "$1" ;; esac; }
backup() { [ -f "$1" ] && cp "$1" "$1.bak-$STAMP" && info "↳ backup: $(short "$1").bak-$STAMP" || true; }
ask()    { [ -r /dev/tty ] || die "no terminal to ask on; use --tools and ZEROG_API_KEY"; read -r "$@" </dev/tty; }

# Runs a command with a spinner; its stdout lands in $SPIN_OUT.
SPIN_OUT=""
spin() { # message, command...
  local msg="$1"; shift
  local out; out="$(mktemp)"
  if [ "$FANCY" = 1 ]; then
    "$@" >"$out" 2>/dev/null &
    local pid=$! i=0 frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    while kill -0 "$pid" 2>/dev/null; do
      printf '\r  %s%s%s %s' "$P2" "${frames[i % 10]}" "$R" "$msg"
      i=$((i+1)); sleep 0.08
    done
    wait "$pid" || true
    printf '\r\033[K'
  else
    "$@" >"$out" 2>/dev/null || true
  fi
  SPIN_OUT="$(cat "$out")"; rm -f "$out"
}

banner() {
  echo
  printf '%s   ██████╗  ██████╗ %s\n' "$P1" "$R"
  printf '%s  ██╔═████╗██╔════╝ %s\n' "$P1" "$R"
  printf '%s  ██║██╔██║██║  ███╗%s   %s0G CLI setup%s\n' "$P2" "$R" "$B" "$R"
  printf '%s  ████╔╝██║██║   ██║%s   %sOne key. 100+ models. Your terminal.%s\n' "$P2" "$R" "$D" "$R"
  printf '%s  ╚██████╔╝╚██████╔╝%s\n' "$P3" "$R"
  printf '%s   ╚═════╝  ╚═════╝ %s\n' "$P3" "$R"
}

command -v curl >/dev/null || die "curl is required"
command -v python3 >/dev/null || die "python3 is required (macOS: xcode-select --install)"

# --- arguments ---------------------------------------------------------------
TOOLS_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --tools) TOOLS_ARG="${2:-}"; shift 2 ;;
    --tools=*) TOOLS_ARG="${1#*=}"; shift ;;
    -h|--help) sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

banner

# --- pick tools --------------------------------------------------------------
IDS=(kilo opencode kimi codex claude)
NAMES=("Kilo CLI" "OpenCode" "Kimi Code CLI" "Codex CLI" "Claude Code")
BINS=(kilo opencode kimi codex claude)
NOTES=("all models" "all models" "all models" "Responses-format models" "Claude + a few others")

installed() { command -v "$1" >/dev/null; }

step "Choose your tools"
SELECTED=()
if [ -n "$TOOLS_ARG" ]; then
  if [ "$TOOLS_ARG" = all ]; then SELECTED=("${IDS[@]}")
  else IFS=, read -ra SELECTED <<<"$TOOLS_ARG"; fi
  for t in "${SELECTED[@]}"; do
    case " ${IDS[*]} " in *" $t "*) ;; *) die "unknown tool '$t' (choose from: ${IDS[*]}, all)";; esac
  done
else
  echo
  for i in "${!IDS[@]}"; do
    if installed "${BINS[$i]}"; then dot="${GRN}●${R}"; st="installed    "
    else dot="${D}○${R}"; st="not installed"; fi
    printf '   %s%d%s  %s %s%-14s%s %s%s  %s%s\n' "$P2$B" "$((i+1))" "$R" "$dot" "$B" "${NAMES[$i]}" "$R" "$D" "$st" "${NOTES[$i]}" "$R"
  done
  printf '   %sa%s    %sAll of the above%s\n\n' "$P2$B" "$R" "$B" "$R"
  while :; do
    printf '  %s›%s Pick one or more %s(e.g. 1 or 1,3)%s: ' "$P2" "$R" "$D" "$R"; ask CHOICE
    CHOICE="${CHOICE// /}"; SELECTED=()
    if [ "$CHOICE" = a ] || [ "$CHOICE" = A ]; then SELECTED=("${IDS[@]}"); break; fi
    valid=1
    IFS=, read -ra picks <<<"$CHOICE"
    for p in "${picks[@]:-}"; do
      if [[ "$p" =~ ^[1-5]$ ]]; then
        t="${IDS[$((p-1))]}"
        case " ${SELECTED[*]:-} " in *" $t "*) ;; *) SELECTED+=("$t");; esac
      else valid=0; fi
    done
    [ "$valid" = 1 ] && [ ${#SELECTED[@]} -gt 0 ] && break
    warn "type numbers 1-5 separated by commas, or a"
  done
fi

picked_names=()
for t in "${SELECTED[@]}"; do
  for i in "${!IDS[@]}"; do [ "${IDS[$i]}" = "$t" ] && picked_names+=("${NAMES[$i]}"); done
done
ok "Setting up: $B$(IFS=,; echo "${picked_names[*]}" | sed 's/,/, /g')$R"

# --- shell rc file -----------------------------------------------------------
case "$(basename "${SHELL:-}")" in
  zsh)  RC="$HOME/.zshrc" ;;
  bash) if [ "$(uname)" = Darwin ]; then RC="$HOME/.bash_profile"; else RC="$HOME/.bashrc"; fi ;;
  *)    RC="$HOME/.profile" ;;
esac
RC_SHORT="$(short "$RC")"

# --- API key -----------------------------------------------------------------
step "Connect your 0G API key"
KEY="${ZEROG_API_KEY:-}"
if [ -n "$KEY" ] && [ -z "$TOOLS_ARG" ] && [ -r /dev/tty ]; then
  printf '  %s›%s Found a saved key %s(sk-...%s)%s. Use it? %s[Y/n]%s: ' "$P2" "$R" "$D" "${KEY: -4}" "$R" "$D" "$R"
  ask USE_ENV
  case "$USE_ENV" in n|N|no|No|NO) KEY="" ;; esac
fi
if [ -n "$KEY" ]; then
  ok "Using your saved key"
else
  if [ -n "${ZEROG_API_KEY:-}" ]; then
    info "OK, enter the key you want to use instead. It replaces the saved one."
  else
    info "No key yet? Get one at https://pc.0g.ai (sign in → Deposit → API Keys → Create)."
  fi
  printf '  %s›%s Paste your key %s(starts with sk-, input hidden)%s: ' "$P2" "$R" "$D" "$R"; ask -s KEY; echo
fi
KEY="${KEY//[[:space:]]/}"
case "$KEY" in sk-*) ;; *) die "that doesn't look like a 0G key (should start with sk-)";; esac

spin "Checking your key with 0G..." curl -s -o /dev/null -w '%{http_code}' -m 60 "$API/v1/chat/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"model":"glm-5.2","max_tokens":5,"messages":[{"role":"user","content":"say OK"}]}'
code="${SPIN_OUT:-000}"
case "$code" in
  200) ok "Key works" ;;
  401) die "0G rejected the key (401). Check it at pc.0g.ai." ;;
  402) warn "Key is valid but your balance is empty (402). Deposit at pc.0g.ai → Dashboard → Deposit." ;;
  *)   warn "Couldn't verify the key (HTTP $code). Continuing setup." ;;
esac

# --- model list --------------------------------------------------------------
MODELS_JSON="$(mktemp)"; trap 'rm -f "$MODELS_JSON"' EXIT
spin "Fetching the 0G model list..." curl -fsS -m 30 "$API/v1/models" -o "$MODELS_JSON"
[ -s "$MODELS_JSON" ] || die "couldn't fetch $API/v1/models"
ok "$(python3 -c 'import json,sys;print(len(json.load(open(sys.argv[1]))["data"]))' "$MODELS_JSON") models available on 0G"

# Writes a named, marker-delimited block into a file, replacing any earlier one.
write_block() { # file, name, content
  python3 - "$1" "$2" "$3" <<'PY'
import os,re,sys
path,name,content=sys.argv[1:4]
b,e=f"# >>> {name} >>>",f"# <<< {name} <<<"
s=open(path).read() if os.path.exists(path) else ""
block=f"{b}\n{content.rstrip()}\n{e}\n"
pat=re.compile(re.escape(b)+r".*?"+re.escape(e)+r"\n?",re.S)
s=pat.sub(lambda _:block,s) if pat.search(s) else (s.rstrip("\n")+"\n\n" if s.strip() else "")+block
open(path,"w").write(s)
PY
}

touch "$RC"; backup "$RC"
write_block "$RC" "0g-cli-setup" "export ZEROG_API_KEY='$KEY'"
chmod 600 "$RC"
ok "Key saved to $RC_SHORT"

# --- configure ---------------------------------------------------------------
step "Configure"
DONE_CMD=(); DONE_DESC=()
done_add() { DONE_CMD+=("$1"); DONE_DESC+=("$2"); }
not_installed_note() { installed "$1" || warn "$2 isn't installed yet; config is ready for when it is"; }

# Kilo is built on OpenCode, so both share this config format.
write_opencode_style() { # file, schema url
  local F="$1"; mkdir -p "$(dirname "$F")"; backup "$F"
  ok "$(python3 - "$F" "$MODELS_JSON" "$API" "$2" <<'PY'
import json,os,re,sys
path,models,api,schema=sys.argv[1:5]
cfg={"$schema":schema}
if os.path.exists(path):
    raw=re.sub(r"^\s*//.*$","",open(path).read(),flags=re.M)
    try: cfg=json.loads(raw) if raw.strip() else cfg
    except ValueError: print(f"  ! couldn't parse existing {os.path.basename(path)}; replaced it (backup kept)",file=sys.stderr)
skip=re.compile(r"^(bytedance/|tencent/)|image|embedding|whisper|ocr|^laya$|^minimax-h3$")
oa,an={},{}
for m in json.load(open(models))["data"]:
    i,c=m["id"],m.get("context_length")
    if not c or skip.search(i): continue
    entry={"name":m.get("name") or i,"limit":{"context":c,"output":min(32768,c//4)}}
    (oa if "openai" in (m.get("supported_formats") or ["openai"]) else an)[i]=entry
key={"apiKey":"{env:ZEROG_API_KEY}"}
p=cfg.setdefault("provider",{})
p["zerog"]={"npm":"@ai-sdk/openai-compatible","name":"0G Router","options":{"baseURL":api+"/v1",**key},"models":oa}
p["zerog-claude"]={"npm":"@ai-sdk/anthropic","name":"0G Router (Claude)","options":{"baseURL":api+"/v1",**key},"models":an}
cfg.setdefault("model","zerog/glm-5.2")
json.dump(cfg,open(path,"w"),indent=2)
print(f"{len(oa)} models under zerog/, {len(an)} under zerog-claude/")
PY
)"
}

setup_kilo() {
  sub "Kilo CLI"; not_installed_note kilo "Kilo CLI"
  write_opencode_style "$HOME/.config/kilo/kilo.jsonc" "https://app.kilo.ai/config.json"
  done_add "kilo" "Kilo on 0G · /models to switch"
}

setup_opencode() {
  sub "OpenCode"; not_installed_note opencode "OpenCode"
  local D="$HOME/.config/opencode" F
  if [ -f "$D/opencode.json" ]; then F="$D/opencode.json"
  elif [ -f "$D/opencode.jsonc" ]; then F="$D/opencode.jsonc"
  else F="$D/opencode.json"; fi
  write_opencode_style "$F" "https://opencode.ai/config.json"
  done_add "opencode" "OpenCode on 0G · /models to switch"
}

setup_kimi() {
  sub "Kimi Code CLI"; not_installed_note kimi "Kimi Code CLI"
  local F="$HOME/.kimi-code/config.toml"; mkdir -p "$(dirname "$F")"; backup "$F"; touch "$F"
  local BLOCK
  BLOCK="$(python3 - "$F" "$MODELS_JSON" "$API" <<'PY'
import json,re,sys
path,models,api=sys.argv[1:4]
s=re.sub(r"# >>> 0g-cli-setup >>>.*?# <<< 0g-cli-setup <<<","",open(path).read(),flags=re.S)
out=[]
if not re.search(r"^\[thinking\]",s,re.M):
    out+=["# 0G rejects Anthropic context_management, which Kimi sends unless keep is off","[thinking]",'keep = "off"',""]
else:
    print('  ! [thinking] already set; make sure it has keep = "off" or Claude will fail',file=sys.stderr)
out+=["[providers.zerog]",'type = "openai"',f'base_url = "{api}/v1"','api_key_env = "ZEROG_API_KEY"',"",
      "[providers.zerog-claude]",'type = "anthropic"',f'base_url = "{api}"','api_key_env = "ZEROG_API_KEY"',""]
skip=re.compile(r"^(bytedance/|tencent/)|image|embedding|whisper|ocr|^laya$|^minimax-h3$")
for m in json.load(open(models))["data"]:
    i,c=m["id"],m.get("context_length")
    if not c or skip.search(i): continue
    p="zerog" if "openai" in (m.get("supported_formats") or ["openai"]) else "zerog-claude"
    out+=[f'[models."{i}"]',f'provider = "{p}"',f'model = "{i}"',f"max_context_size = {c}",""]
print("\n".join(out))
PY
)"
  write_block "$F" "0g-cli-setup" "$BLOCK"
  # default_model must sit above every table
  if ! grep -q '^default_model' "$F"; then
    printf 'default_model = "kimi-k2.7-code"\n\n%s\n' "$(cat "$F")" > "$F"
  fi
  ok "Providers and models written"
  done_add "kimi" "Kimi Code on 0G · kimi -m claude-sonnet-5 for Claude"
}

setup_codex() {
  sub "Codex CLI"; not_installed_note codex "Codex CLI"
  mkdir -p "$HOME/.codex"
  local F="$HOME/.codex/config.toml"; backup "$F"; touch "$F"
  if grep -q '^\[profiles\.zerog\]' "$F"; then
    warn "found a legacy [profiles.zerog] table in $F; remove it or Codex will refuse -p zerog"
  fi
  if grep -q '^\[model_providers\.zerog\]' "$F" && ! grep -q '# >>> 0g-cli-setup >>>' "$F"; then
    warn "$(short "$F") already defines [model_providers.zerog]; left it as is"
  else
    write_block "$F" "0g-cli-setup" "[model_providers.zerog]
name = \"0G Router\"
base_url = \"$API/v1\"
env_key = \"ZEROG_API_KEY\"
wire_api = \"responses\""
  fi
  # Codex only speaks the Responses API, which a subset of 0G models support
  local RESP CODEX_MODEL="" m
  RESP="$(python3 -c '
import json,sys
print(" ".join(m["id"] for m in json.load(open(sys.argv[1]))["data"] if "responses" in (m.get("supported_formats") or [])))' "$MODELS_JSON")"
  for m in glm-5.3-flash qwen3-coder-flash deepseek-v4-flash $RESP; do
    case " $RESP " in *" $m "*) CODEX_MODEL="$m"; break ;; esac
  done
  if [ -z "$CODEX_MODEL" ]; then
    warn "no 0G model currently supports the Responses API Codex needs; skipped the profile"
    return
  fi
  local P="$HOME/.codex/zerog.config.toml"; backup "$P"
  printf 'model_provider = "zerog"\nmodel = "%s"\n' "$CODEX_MODEL" > "$P"
  ok "Provider and zerog profile written (default: $B$CODEX_MODEL$R)"
  info "Models Codex can use: $RESP"
  done_add "codex -p zerog" "Codex on 0G · $CODEX_MODEL, or -m <model>"
}

setup_claude() {
  sub "Claude Code"; not_installed_note claude "Claude Code"
  write_block "$RC" "0g-cli-setup claude" "# Claude Code on 0G; plain \`claude\` keeps your normal login
claude-0g() {
  CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1 \\
  ANTHROPIC_BASE_URL=\"$API\" \\
  ANTHROPIC_AUTH_TOKEN=\"\$ZEROG_API_KEY\" \\
  ANTHROPIC_API_KEY=\"\" \\
  ANTHROPIC_MODEL=\"claude-sonnet-5\" \\
  ANTHROPIC_DEFAULT_OPUS_MODEL=\"claude-opus-5.5\" \\
  ANTHROPIC_DEFAULT_SONNET_MODEL=\"claude-sonnet-5\" \\
  ANTHROPIC_DEFAULT_HAIKU_MODEL=\"claude-sonnet-4.5\" \\
  claude \"\$@\"
}"
  ok "claude-0g command added to $RC_SHORT"
  done_add "claude-0g" "Claude Code on 0G · plain claude is unchanged"
}

for t in "${SELECTED[@]}"; do "setup_$t"; done

# --- summary -----------------------------------------------------------------
RULE="────────────────────────────────────────────────────────────"
echo
printf '  %s╭%s%s\n' "$P2" "$RULE" "$R"
printf '  %s│%s  %s%s✓ Installation complete%s\n' "$P2" "$R" "$GRN" "$B" "$R"
printf '  %s│%s\n' "$P2" "$R"
printf '  %s│%s  You can now run:\n' "$P2" "$R"
printf '  %s│%s\n' "$P2" "$R"
for i in "${!DONE_CMD[@]}"; do
  printf '  %s│%s    %s%s%-16s%s %s%s%s\n' "$P2" "$R" "$GRN" "$B" "${DONE_CMD[$i]}" "$R" "$D" "${DONE_DESC[$i]}" "$R"
done
printf '  %s│%s\n' "$P2" "$R"
printf '  %s│%s  %sFirst, open a new terminal or run:%s %ssource %s%s\n' "$P2" "$R" "$D" "$R" "$B" "$RC_SHORT" "$R"
printf '  %s│%s  %sBackups saved as *.bak-%s · guide: %s%s\n' "$P2" "$R" "$D" "$STAMP" "$REPO" "$R"
printf '  %s╰%s%s\n\n' "$P2" "$RULE" "$R"
