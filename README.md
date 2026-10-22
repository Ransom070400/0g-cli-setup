# Using the 0G API from your terminal: Kilo, Codex, Kimi Code and Claude Code

One 0G API key gives your coding CLIs access to 100+ models (Claude, GPT, Gemini, GLM, Kimi, Qwen, DeepSeek and more) through a single endpoint: `https://router-api.0g.ai/v1`.

This guide sets up four terminal coding agents to use it: **Kilo CLI**, **OpenAI Codex CLI**, **Kimi Code CLI** and **Claude Code**. Each takes about five minutes. Every config below was tested end to end on macOS with zsh. Ready-to-copy files are in [`configs/`](configs/).

One thing to know up front: the 0G Router speaks two API formats. Most models use the OpenAI format, but **Claude models only work in Anthropic's format** (`/v1/messages`). That decides which tools can reach Claude, and why some configs below have two providers.

| Tool | Non-Claude models | Claude models |
| --- | --- | --- |
| Kilo CLI | Yes (`zerog`) | Yes (`zerog-claude`) |
| Codex CLI | Yes (`-p zerog`) | No: Responses format only |
| Kimi Code CLI | Yes (`zerog`) | Yes, with `keep = "off"` |
| Claude Code | No: Anthropic format only | Yes (`claude-0g`) |

## Step 1: Get a key and save it once

Create an API key at [pc.0g.ai](https://pc.0g.ai). It starts with `sk-`. Note that pc.0g.ai is the dashboard, not the API; the API lives at `router-api.0g.ai`.

Save the key as an environment variable so every tool can read it without pasting it into config files:

1. Open your shell config: `open -e ~/.zshrc`
2. Add this line at the bottom (no spaces around `=`, no quotes):

   ```bash
   export ZEROG_API_KEY=sk-your-key-here
   ```

3. Save, then run `source ~/.zshrc`. New terminal windows pick it up automatically; you only `source` once.

Check that the key works:

```bash
curl https://router-api.0g.ai/v1/chat/completions \
  -H "Authorization: Bearer $ZEROG_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"glm-5.2","messages":[{"role":"user","content":"say OK"}]}'
```

To see every model ID and context size: `curl https://router-api.0g.ai/v1/models`

## Step 2: Kilo CLI

Kilo can use every 0G model, including Claude, by defining two providers: one in OpenAI format and one in Anthropic format.

Copy [`configs/kilo.jsonc`](configs/kilo.jsonc) to `~/.config/kilo/kilo.jsonc`:

```jsonc
{
  "$schema": "https://app.kilo.ai/config.json",
  "model": "zerog/glm-5.2",
  "provider": {
    "zerog": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "0G Router",
      "options": {
        "baseURL": "https://router-api.0g.ai/v1",
        "apiKey": "{env:ZEROG_API_KEY}"
      },
      "models": {
        "glm-5.2": { "limit": { "context": 1179648, "output": 32768 } },
        "kimi-k2.7-code": { "limit": { "context": 262144, "output": 32768 } },
        "deepseek-v4-pro": { "limit": { "context": 1441792, "output": 32768 } }
      }
    },
    "zerog-claude": {
      "npm": "@ai-sdk/anthropic",
      "name": "0G Router (Claude)",
      "options": {
        "baseURL": "https://router-api.0g.ai/v1",
        "apiKey": "{env:ZEROG_API_KEY}"
      },
      "models": {
        "claude-sonnet-5": { "limit": { "context": 1000000, "output": 32768 } }
      }
    }
  }
}
```

Add any other model ID from `/v1/models` the same way. Keep this in your global config: `{env:...}` only resolves in trusted config files.

Test it:

```bash
kilo models zerog
kilo run -m zerog/glm-5.2 "say hi"
kilo run -m zerog-claude/claude-sonnet-5 "say hi"
```

In the app, switch models with `/models`. If you use Kilo's login flow instead of the env var (`kilo auth login`), choose **Other**, not Kilo Gateway, and enter `zerog` as the provider ID.

## Step 3: OpenAI Codex CLI

Codex can use every 0G model except Claude, because Codex only speaks OpenAI's Responses format. Setting it up as a profile keeps your normal ChatGPT login as the default.

1. Add the provider to the end of `~/.codex/config.toml` ([`configs/codex-config.toml`](configs/codex-config.toml)):

   ```toml
   [model_providers.zerog]
   name = "0G Router"
   base_url = "https://router-api.0g.ai/v1"
   env_key = "ZEROG_API_KEY"
   wire_api = "responses"
   ```

2. Create the profile as its own file, `~/.codex/zerog.config.toml` ([`configs/codex-zerog.config.toml`](configs/codex-zerog.config.toml)):

   ```toml
   model_provider = "zerog"
   model = "glm-5.2"
   ```

   Recent Codex versions require profiles in separate files. A `[profiles.zerog]` table inside `config.toml` fails with "cannot be used while config.toml contains legacy profile config".

3. Run it:

   ```bash
   codex -p zerog
   codex -p zerog -m kimi-k2.7-code   # any non-Claude 0G model
   ```

Codex prints `Model metadata for glm-5.2 not found` on startup. That warning is harmless: it just uses default settings for models it doesn't know.

## Step 4: Kimi Code CLI

Kimi Code supports both API formats, so it can use every 0G model including Claude. Its config lives at `~/.kimi-code/config.toml` (not `~/.kimi`, which older docs mention).

Copy [`configs/kimi-config.toml`](configs/kimi-config.toml) to `~/.kimi-code/config.toml`:

```toml
default_model = "kimi-k2.7-code"

# Required for Claude on 0G (see below)
[thinking]
keep = "off"

[providers.zerog]
type = "openai"
base_url = "https://router-api.0g.ai/v1"
api_key_env = "ZEROG_API_KEY"

[providers.zerog-claude]
type = "anthropic"
base_url = "https://router-api.0g.ai"
api_key_env = "ZEROG_API_KEY"

[models."kimi-k2.7-code"]
provider = "zerog"
model = "kimi-k2.7-code"
max_context_size = 262144

[models."glm-5.2"]
provider = "zerog"
model = "glm-5.2"
max_context_size = 1179648

[models."claude-sonnet-5"]
provider = "zerog-claude"
model = "claude-sonnet-5"
max_context_size = 1000000
```

Two details matter:

- The Anthropic provider's `base_url` has **no** `/v1`; Kimi adds `/v1/messages` itself.
- `[thinking] keep = "off"` stops Kimi from sending Anthropic's `context_management` field, which 0G rejects. Without it, Claude fails with "The upstream provider rejected the request." It applies to all models, so earlier reasoning isn't carried between steps.

Run it from your project folder: `kimi`, or `kimi -m claude-sonnet-5`. If it offers a Kimi account login, skip it; you don't need one, and logging in can rewrite the config.

## Step 5: Claude Code

Claude Code speaks Anthropic's format natively, so it can run on 0G's Claude models (not the others). A shell function keeps it separate: `claude-0g` uses 0G, while plain `claude` keeps your normal Anthropic login.

Add [`configs/claude-code.zsh`](configs/claude-code.zsh) to the end of `~/.zshrc`:

```bash
claude-0g() {
  CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1 \
  ANTHROPIC_BASE_URL="https://router-api.0g.ai" \
  ANTHROPIC_AUTH_TOKEN="$ZEROG_API_KEY" \
  ANTHROPIC_API_KEY="" \
  ANTHROPIC_MODEL="claude-sonnet-5" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-5.5" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="claude-sonnet-5" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="claude-sonnet-4.5" \
  claude "$@"
}
```

Then `source ~/.zshrc` and run:

```bash
claude-0g                    # Claude Sonnet 5 on 0G
claude-0g --model opus       # Claude Opus 5.5 on 0G
claude-0g --model claude-opus-4.7   # any Claude ID from /v1/models
```

What each line does:

- `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` is required. Without it, Claude Code sends Anthropic beta features 0G doesn't support, and every request fails with "API Error: 400 The upstream provider rejected the request."
- `ANTHROPIC_BASE_URL` has **no** `/v1`; Claude Code adds `/v1/messages` itself.
- `ANTHROPIC_AUTH_TOKEN` sends your 0G key as a Bearer token. `ANTHROPIC_API_KEY=""` stops any real Anthropic key from being used instead.
- The model lines map Claude Code's names to 0G's model IDs, which use dots (`claude-opus-5.5`). 0G has no Haiku, so background tasks use Sonnet 4.5.

On startup Claude Code warns that claude.ai connectors are disabled. That's expected when it uses another provider, and only affects `claude-0g`.

## Troubleshooting

| Error | Cause | Fix |
| --- | --- | --- |
| `Missing environment variable: ZEROG_API_KEY` | Key not in `~/.zshrc`, or terminal opened before you added it | Add the export line, then `source ~/.zshrc` or open a new terminal |
| `Invalid authentication token` | Wrong or old key stored | Re-check the key at pc.0g.ai; for Kilo's auth store, rerun `kilo auth login` |
| `model "claude-..." is not available on the openai API format` | Claude sent in OpenAI format | Use an Anthropic-type provider (Kilo, Kimi); not possible in Codex |
| `--profile zerog cannot be used while config.toml contains legacy ... config` | Codex profile inside `config.toml` | Move it to `~/.codex/zerog.config.toml` |
| `The upstream provider rejected the request` (Kimi + Claude) | Kimi sends `context_management` | Add `[thinking] keep = "off"` |
| `API Error: 400 The upstream provider rejected the request` (Claude Code) | Claude Code sends beta features 0G rejects | Set `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` |
| 404 on `pc.0g.ai/v1/...` | Dashboard URL used as the API | Use `https://router-api.0g.ai/v1` |

## Saving tokens

Coding agents use more tokens than chat because they re-send the whole conversation on every step. In testing, a one-word Codex reply cost 12,609 tokens, all of it Codex's own instructions and tool list. A short real task cost 620,913 tokens, about 90% of them cached repeats.

- **Start fresh between tasks** with `/new`, and use `/compact` when a session gets long, so old file contents stop being re-sent.
- **Name the file and line** you want changed, so the agent reads one file instead of exploring.
- **Use a flash model for simple jobs** (`glm-5.3-flash`, `deepseek-v4-flash`, `qwen3.7-flash`) and save the big models for hard work.
- **Lower reasoning effort** for routine tasks; in Codex, add `model_reasoning_effort = "low"` to `~/.codex/zerog.config.toml`.

## Sources

- [0G Router quickstart](https://docs.0g.ai/developer-hub/building-on-0g/compute-network/router/quickstart)
- [Kilo CLI docs](https://kilo.ai/docs/cli)
- [Kimi Code: Providers and models](https://www.kimi.com/code/docs/en/kimi-code-cli/configuration/providers.html)
- [Claude Code: LLM gateway configuration](https://code.claude.com/docs/en/llm-gateway)
