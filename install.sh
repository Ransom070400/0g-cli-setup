#!/usr/bin/env bash
# One-command setup: point Kilo, Codex, Kimi Code and Claude Code at the 0G Router.
#   curl -fsSL https://raw.githubusercontent.com/<you>/0g-cli-setup/main/install.sh | bash
# Safe to re-run: it replaces its own blocks and backs up every file it touches.
set -euo pipefail

API="https://router-api.0g.ai"
MARK_BEGIN="# >>> 0g-cli-setup >>>"
MARK_END="# <<< 0g-cli-setup <<<"
STAMP="$(date +%Y%m%d-%H%M%S)"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

backup() { [ -f "$1" ] && cp "$1" "$1.bak-$STAMP" && ok "backed up $1 → $1.bak-$STAMP" || true; }

command -v curl >/dev/null || die "curl is required"
command -v python3 >/dev/null || die "python3 is required (macOS: xcode-select --install)"

# --- shell rc file -----------------------------------------------------------
case "$(basename "${SHELL:-}")" in
  zsh)  RC="$HOME/.zshrc" ;;
  bash) if [ "$(uname)" = Darwin ]; then RC="$HOME/.bash_profile"; else RC="$HOME/.bashrc"; fi ;;
  *)    RC="$HOME/.profile" ;;
esac

# --- API key -----------------------------------------------------------------
say "0G API key"
KEY="${ZEROG_API_KEY:-}"
if [ -n "$KEY" ]; then
  ok "using ZEROG_API_KEY from your environment"
else
  [ -r /dev/tty ] || die "no terminal to read the key from; run: ZEROG_API_KEY=sk-... bash install.sh"
  printf '  Paste your key from pc.0g.ai (starts with sk-, input hidden): '
  read -rs KEY </dev/tty; echo
fi
case "$KEY" in sk-*) ;; *) die "that doesn't look like a 0G key (should start with sk-)";; esac

code=$(curl -s -o /dev/null -w '%{http_code}' -m 60 "$API/v1/chat/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"model":"glm-5.2","max_tokens":5,"messages":[{"role":"user","content":"say OK"}]}' || echo 000)
case "$code" in
  200) ok "key works" ;;
  401) die "0G rejected the key (401). Check it at pc.0g.ai." ;;
  402) warn "key is valid but your balance is empty (402). Deposit at pc.0g.ai → Dashboard → Deposit. Continuing setup." ;;
  *)   warn "couldn't verify the key (HTTP $code). Continuing setup." ;;
esac

# --- model list --------------------------------------------------------------
say "Fetching 0G model list"
MODELS_JSON="$(mktemp)"; trap 'rm -f "$MODELS_JSON"' EXIT
curl -fsS -m 30 "$API/v1/models" -o "$MODELS_JSON" || die "couldn't fetch $API/v1/models"
ok "$(python3 -c 'import json,sys;print(len(json.load(open(sys.argv[1]))["data"]))' "$MODELS_JSON") models available"

# Writes a marker-delimited block into a file, replacing any earlier one.
write_block() { # file, content
  python3 - "$1" "$2" "$MARK_BEGIN" "$MARK_END" <<'PY'
import os,re,sys
path,content,b,e=sys.argv[1:5]
s=open(path).read() if os.path.exists(path) else ""
block=f"{b}\n{content.rstrip()}\n{e}\n"
pat=re.compile(re.escape(b)+r".*?"+re.escape(e)+r"\n?",re.S)
s=pat.sub(lambda _:block,s) if pat.search(s) else (s.rstrip("\n")+"\n\n" if s.strip() else "")+block
open(path,"w").write(s)
PY
}

# --- key + claude-0g in shell rc --------------------------------------------
say "Saving key to $RC"
backup "$RC"
RC_BLOCK="export ZEROG_API_KEY='$KEY'"
if command -v claude >/dev/null; then
  RC_BLOCK="$RC_BLOCK
# Claude Code on 0G; plain \`claude\` keeps your normal login
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
fi
touch "$RC"; write_block "$RC" "$RC_BLOCK"; chmod 600 "$RC"
ok "ZEROG_API_KEY saved"

DONE=()

# --- Kilo --------------------------------------------------------------------
if command -v kilo >/dev/null; then
  say "Kilo CLI"
  F="$HOME/.config/kilo/kilo.jsonc"; mkdir -p "$(dirname "$F")"; backup "$F"
  python3 - "$F" "$MODELS_JSON" "$API" <<'PY'
import json,os,re,sys
path,models,api=sys.argv[1:4]
cfg={"$schema":"https://app.kilo.ai/config.json"}
if os.path.exists(path):
    raw=re.sub(r"^\s*//.*$","",open(path).read(),flags=re.M)
    try: cfg=json.loads(raw) if raw.strip() else cfg
    except ValueError: print("  ! couldn't parse existing kilo.jsonc; replaced it (backup kept)")
skip=re.compile(r"^(bytedance/|tencent/)|image|embedding|whisper|ocr|^laya$|^minimax-h3$")
oa,an={},{}
for m in json.load(open(models))["data"]:
    i,c=m["id"],m.get("context_length")
    if not c or skip.search(i): continue
    entry={"name":m.get("name") or i,"limit":{"context":c,"output":min(32768,c//4)}}
    fm=m.get("supported_formats") or ["openai"]
    (oa if "openai" in fm else an)[i]=entry
key={"apiKey":"{env:ZEROG_API_KEY}"}
p=cfg.setdefault("provider",{})
p["zerog"]={"npm":"@ai-sdk/openai-compatible","name":"0G Router","options":{"baseURL":api+"/v1",**key},"models":oa}
p["zerog-claude"]={"npm":"@ai-sdk/anthropic","name":"0G Router (Claude)","options":{"baseURL":api+"/v1",**key},"models":an}
cfg.setdefault("model","zerog/glm-5.2")
json.dump(cfg,open(path,"w"),indent=2)
print(f"  ✓ {len(oa)} models under zerog/, {len(an)} under zerog-claude/")
PY
  DONE+=("kilo                      Kilo on 0G (zerog/glm-5.2 unless you had a default)")
fi

# --- Codex -------------------------------------------------------------------
if command -v codex >/dev/null; then
  say "Codex CLI"
  mkdir -p "$HOME/.codex"
  F="$HOME/.codex/config.toml"; backup "$F"; touch "$F"
  if grep -q '^\[profiles\.zerog\]' "$F"; then
    warn "found a legacy [profiles.zerog] table in $F; remove it or Codex will refuse -p zerog"
  fi
  if grep -q '^\[model_providers\.zerog\]' "$F" && ! grep -qF "$MARK_BEGIN" "$F"; then
    warn "$F already defines [model_providers.zerog]; left it as is"
  else
    write_block "$F" "[model_providers.zerog]
name = \"0G Router\"
base_url = \"$API/v1\"
env_key = \"ZEROG_API_KEY\"
wire_api = \"responses\""
  fi
  # Codex only speaks the Responses API, which a subset of 0G models support
  RESP="$(python3 -c '
import json,sys
print(" ".join(m["id"] for m in json.load(open(sys.argv[1]))["data"] if "responses" in (m.get("supported_formats") or [])))' "$MODELS_JSON")"
  CODEX_MODEL=""
  for m in glm-5.3-flash qwen3-coder-flash deepseek-v4-flash $RESP; do
    case " $RESP " in *" $m "*) CODEX_MODEL="$m"; break ;; esac
  done
  if [ -z "$CODEX_MODEL" ]; then
    warn "no 0G model currently supports the Responses API Codex needs; skipped the profile"
  else
    P="$HOME/.codex/zerog.config.toml"; backup "$P"
    printf 'model_provider = "zerog"\nmodel = "%s"\n' "$CODEX_MODEL" > "$P"
    ok "provider + zerog profile written (default model: $CODEX_MODEL)"
    ok "models Codex can use: $RESP"
    DONE+=("codex -p zerog            Codex on 0G ($CODEX_MODEL; others listed above, via -m)")
  fi
fi

# --- Kimi Code ---------------------------------------------------------------
if command -v kimi >/dev/null; then
  say "Kimi Code CLI"
  F="$HOME/.kimi-code/config.toml"; mkdir -p "$(dirname "$F")"; backup "$F"; touch "$F"
  BLOCK="$(python3 - "$F" "$MODELS_JSON" "$API" "$MARK_BEGIN" "$MARK_END" <<'PY'
import json,re,sys
path,models,api,b,e=sys.argv[1:6]
s=re.sub(re.escape(b)+r".*?"+re.escape(e),"",open(path).read(),flags=re.S)
out=[]
if not re.search(r"^\[thinking\]",s,re.M):
    out+=["# 0G rejects Anthropic context_management, which Kimi sends unless keep is off","[thinking]",'keep = "off"',""]
else:
    print("  ! [thinking] already set; make sure it has keep = \"off\" or Claude will fail",file=sys.stderr)
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
  write_block "$F" "$BLOCK"
  # default_model must sit above every table
  if ! grep -q '^default_model' "$F"; then
    printf 'default_model = "kimi-k2.7-code"\n\n%s\n' "$(cat "$F")" > "$F"
  fi
  ok "providers + models written"
  DONE+=("kimi                      Kimi Code on 0G (kimi -m claude-sonnet-5 for Claude)")
fi

if command -v claude >/dev/null; then
  DONE+=("claude-0g                 Claude Code on 0G (plain claude is unchanged)")
fi

# --- summary -----------------------------------------------------------------
echo
if [ ${#DONE[@]} -eq 0 ]; then
  warn "none of kilo, codex, kimi or claude are installed; only the key was saved"
else
  say "Done. Open a new terminal (or run: source $RC), then:"
  for l in "${DONE[@]}"; do printf '    %s\n' "$l"; done
fi
echo "    Backups: *.bak-$STAMP next to each changed file"
