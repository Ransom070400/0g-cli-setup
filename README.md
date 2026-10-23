# Use the 0G API from your terminal

**One 0G API key, 100+ models (Claude, GPT, Gemini, GLM, Kimi, Qwen, DeepSeek and more), in the coding agents you already use: Kilo, OpenCode, Kimi Code, Codex and Claude Code.**

Setup takes two steps:

1. **[Get a funded API key](#step-1-get-your-api-key)** at pc.0g.ai (a few minutes, once).
2. **Connect your tools**, either way:
   - **[Option A: the install script](#option-a-install-with-the-script)**: one command; it asks which tools you want and does the rest.
   - **[Option B: by hand](#option-b-set-up-manually)**: copy the config for each tool yourself.

Everything here was tested end to end on macOS with zsh. Ready-to-copy config files are in [`configs/`](configs/).

## Which tools can use which models

The 0G Router speaks three API formats: OpenAI Chat Completions, OpenAI Responses and Anthropic Messages. Each model supports some of them, and that decides which tools can use it:

| Tool | API format it speaks | Models it can use on 0G |
| --- | --- | --- |
| [Kilo CLI](#kilo-cli) | OpenAI Chat + Anthropic | All |
| [OpenCode](#opencode) | OpenAI Chat + Anthropic | All |
| [Kimi Code CLI](#kimi-code-cli) | OpenAI Chat + Anthropic | All (Claude needs one extra setting) |
| [Codex CLI](#openai-codex-cli) | OpenAI Responses | Only models listing `responses` (14 today, incl. GLM 5.3 Flash, Qwen3 Coder Flash, GPT-6.1 Sol) |
| [Claude Code](#claude-code) | Anthropic | Claude, plus GLM 5.3, DeepSeek V4, MiMo and a few others |

To check a model's formats, look at `supported_formats` in `curl https://router-api.0g.ai/v1/models`.

## Contents

1. [Step 1: Get your API key](#step-1-get-your-api-key): [sign in](#1-sign-in) · [deposit](#2-deposit-0g-tokens) · [create the key](#3-create-the-key)
2. [Step 2: Connect your tools](#step-2-connect-your-tools)
   - [Option A: Install with the script](#option-a-install-with-the-script)
   - [Option B: Set up manually](#option-b-set-up-manually): [save your key](#save-your-key) · [Kilo CLI](#kilo-cli) · [OpenCode](#opencode) · [Kimi Code CLI](#kimi-code-cli) · [Codex CLI](#openai-codex-cli) · [Claude Code](#claude-code)
3. [Troubleshooting](#troubleshooting)
4. [Saving tokens](#saving-tokens)
5. [Sources](#sources)

## Step 1: Get your API key

You need three things before any tool will work: a 0G account, a deposit of 0G tokens, and an API key. Both setup options need this.

### 1. Sign in

Go to [pc.0g.ai](https://pc.0g.ai) and click **Get API Key**. You can sign in two ways:

- **With a crypto wallet**: MetaMask or WalletConnect.
- **With a social account**: Google, X, Discord or TikTok. This creates a wallet for you automatically, so you don't need one already.

### 2. Deposit 0G tokens

The Router is pay-as-you-go: there's no subscription, and each request is paid from a balance you deposit up front.

1. Open **Dashboard → Deposit**.
2. Enter an amount of 0G tokens and confirm the transaction in your wallet. It's a normal on-chain transaction.
3. The balance is usable a few seconds after the transaction confirms.

Use **mainnet** for real work. Mainnet and testnet have separate balances and separate API keys, so a key made on one won't spend tokens deposited on the other.

You need 0G tokens in your wallet on 0G mainnet before you can deposit. The docs don't state a minimum deposit amount.

### 3. Create the key

1. Open **Dashboard → API Keys** and click **Create**.
2. Copy the key right away. It starts with `sk-`, and **0G never shows it again**. If you lose it, create a new one.

Keep the key out of code, screenshots and git repos. Anyone with it can spend your balance.

Note that pc.0g.ai is the dashboard, not the API. Every tool points at `router-api.0g.ai`.

[↑ Back to contents](#contents)

## Step 2: Connect your tools

Pick one option. Both end in the same place: your key saved as `ZEROG_API_KEY`, and each tool configured to use 0G.

| | Option A: script | Option B: manual |
| --- | --- | --- |
| Time | About a minute | About five minutes per tool |
| Models added | Every 0G model, from the live list | The few in the example configs, plus any you add |
| Best for | Getting started fast | Seeing exactly what changes, or custom setups |

### Option A: Install with the script

Run this in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/Ransom070400/0g-cli-setup/main/install.sh | bash
```

It walks you through three steps:

```text
   ██████╗  ██████╗
  ██╔═████╗██╔════╝
  ██║██╔██║██║  ███╗   0G CLI setup
  ████╔╝██║██║   ██║   One key. 100+ models. Your terminal.
  ╚██████╔╝╚██████╔╝
   ╚═════╝  ╚═════╝

[1/3] Choose your tools

   1  ● Kilo CLI       installed      all models
   2  ● OpenCode       installed      all models
   3  ● Kimi Code CLI  installed      all models
   4  ● Codex CLI      installed      Responses-format models
   5  ● Claude Code    installed      Claude + a few others
   a    All of the above

  › Pick one or more (e.g. 1 or 1,3): 1,4

[2/3] Connect your 0G API key
  › Paste your key (starts with sk-, input hidden):
  ✓ Key works

[3/3] Configure
  ...

  ╭────────────────────────────────────────────────────────────
  │  ✓ Installation complete
  │
  │  You can now run:
  │
  │    kilo             Kilo on 0G · /models to switch
  │    codex -p zerog   Codex on 0G · glm-5.3-flash, or -m <model>
  │
  │  First, open a new terminal or run: source ~/.zshrc
  ╰────────────────────────────────────────────────────────────
```

What it does:

- **Asks which tools to set up**, marking which ones you have installed. Pick one (`1`), several (`1,4`) or all (`a`).
- **Asks for your key** (hidden as you type) and checks it with 0G. If you already have a key saved from an earlier run, it shows the last four characters and asks whether to use it; answer `n` to replace it.
- **Configures each tool** with 0G's live model list, and saves the key to your shell config (`~/.zshrc` on most Macs).
- **Ends with the commands to run**, like `kilo`, `codex -p zerog` or `claude-0g`.

Open a new terminal afterwards (or run `source ~/.zshrc`) so the key is loaded.

**Safe to re-run.** Run it again to add another tool, change your key, or pick up new 0G models. It replaces its own changes instead of duplicating them, and leaves the rest of your config alone.

**Backups.** Before changing any file, it saves a copy next to it as `<file>.bak-<date-time>`. To undo, restore that copy. Everything it adds to `~/.zshrc` and TOML configs sits between `# >>> 0g-cli-setup >>>` and `# <<< 0g-cli-setup <<<` lines, so it's easy to find and delete.

**No prompts (for scripts or CI):**

```bash
curl -fsSL https://raw.githubusercontent.com/Ransom070400/0g-cli-setup/main/install.sh | ZEROG_API_KEY=sk-... bash -s -- --tools kilo,codex
```

`--tools` takes any of `kilo`, `opencode`, `kimi`, `codex`, `claude`, or `all`.

Prefer to read it first? It's a single file: [`install.sh`](install.sh). It needs `curl` and `python3`, which macOS and most Linux systems already have.

[↑ Back to contents](#contents)

### Option B: Set up manually

Save your key once, then follow the section for each tool you use.

#### Save your key

Save the key as an environment variable so every tool can read it without pasting it into config files:

1. Open your shell config: `open -e ~/.zshrc`
2. Add this line at the bottom (no spaces around `=`, no quotes):

   ```bash
   export ZEROG_API_KEY=sk-your-key-here
   ```

3. Save, then run `source ~/.zshrc`. New terminal windows pick it up automatically; you only `source` once.

Check that the key and balance work:

```bash
curl https://router-api.0g.ai/v1/chat/completions \
  -H "Authorization: Bearer $ZEROG_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"glm-5.2","messages":[{"role":"user","content":"say OK"}]}'
```

A reply means you're ready. A `402 insufficient_balance` error means the key works but the deposit hasn't landed or ran out.

#### Kilo CLI

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

[↑ Back to contents](#contents)

#### OpenCode

Kilo is built on OpenCode, so the setup is the same: two providers, one in OpenAI format and one in Anthropic format, giving you every 0G model including Claude.

Copy [`configs/opencode.json`](configs/opencode.json) to `~/.config/opencode/opencode.json`. If you already have that file, add the `zerog` and `zerog-claude` entries under `provider` instead of replacing it. The only difference from the Kilo file is the `$schema` line.

Test it:

```bash
opencode run -m zerog/glm-5.2 "say hi"
opencode run -m zerog-claude/claude-sonnet-5 "say hi"
```

In the app, switch models with `/models`. If you use OpenCode's `/connect` instead of the env var, enter `zerog` as the provider ID.

[↑ Back to contents](#contents)

#### Kimi Code CLI

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

[↑ Back to contents](#contents)

#### OpenAI Codex CLI

Codex only speaks OpenAI's Responses format, and on 0G only some models support it: those with `responses` in `supported_formats`. List them with:

```bash
curl -s https://router-api.0g.ai/v1/models | python3 -c "import json,sys;print([m['id'] for m in json.load(sys.stdin)['data'] if 'responses' in m.get('supported_formats',[])])"
```

Setting it up as a profile keeps your normal ChatGPT login as the default.

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
   model = "glm-5.3-flash"
   ```

   Recent Codex versions require profiles in separate files. A `[profiles.zerog]` table inside `config.toml` fails with "cannot be used while config.toml contains legacy profile config".

3. Run it:

   ```bash
   codex -p zerog
   codex -p zerog -m qwen3-coder-flash   # any model from the list above
   ```

Picking a model outside that list, including from Codex's own `/model` menu, fails with `not available on the responses API format`. Codex dropped support for the older chat format, so there's no workaround inside Codex; use Kilo, OpenCode or Kimi Code for those models.

Codex prints `Model metadata for glm-5.3-flash not found` on startup. That warning is harmless: it just uses default settings for models it doesn't know.

[↑ Back to contents](#contents)

#### Claude Code

Claude Code speaks Anthropic's format, so on 0G it can use the Claude models plus every other model that supports that format. At the time of writing those are `glm-5.3`, `glm-5.3-flash`, `glm-5.3-flashx`, `deepseek-v4-pro`, `deepseek-v4-flash`, `mimo-v2.6-pro`, `mimo-v2.6-flash`, `step-5-preview`, `hy4-preview` and `0gm-1.0-35b-a3b`.

A shell function keeps it separate: `claude-0g` uses 0G, while plain `claude` keeps your normal Anthropic login.

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
claude-0g --model glm-5.3    # cheaper non-Claude model
```

What each line does:

- `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` is required. Without it, Claude Code sends Anthropic beta features 0G doesn't support, and every request fails with "API Error: 400 The upstream provider rejected the request."
- `ANTHROPIC_BASE_URL` has **no** `/v1`; Claude Code adds `/v1/messages` itself.
- `ANTHROPIC_AUTH_TOKEN` sends your 0G key as a Bearer token. `ANTHROPIC_API_KEY=""` stops any real Anthropic key from being used instead.
- The model lines map Claude Code's names to 0G's model IDs, which use dots (`claude-opus-5.5`). 0G has no Haiku, so background tasks use Sonnet 4.5.

On startup Claude Code warns that claude.ai connectors are disabled. That's expected when it uses another provider, and only affects `claude-0g`. With a non-Claude model it may also log `unrecognized_model`; that's harmless.

[↑ Back to contents](#contents)

## Troubleshooting

| Error | Cause | Fix |
| --- | --- | --- |
| `402 insufficient_balance` | No deposit, deposit still confirming, or balance used up | Deposit more at **Dashboard → Deposit**; check you're on mainnet |
| `401 invalid_api_key` / `Invalid authentication token` | Wrong key, or a testnet key used against a mainnet balance | Re-check the key at pc.0g.ai; for Kilo's auth store, rerun `kilo auth login` |
| `401 api_key_revoked` | Key was revoked in the dashboard | Create a new key |
| `Missing environment variable: ZEROG_API_KEY` | Key not in `~/.zshrc`, or terminal opened before you added it | Add the export line, then `source ~/.zshrc` or open a new terminal |
| `model "..." is not available on the openai API format` (or `anthropic`) | The tool's format isn't one the model supports | Check `supported_formats`; for Claude use Kilo, OpenCode, Kimi or Claude Code |
| `model "..." is not available on the responses API format` (Codex) | Model doesn't support the Responses format Codex needs | Use a model listing `responses`, e.g. `codex -p zerog -m glm-5.3-flash` |
| `--profile zerog cannot be used while config.toml contains legacy ... config` | Codex profile inside `config.toml` | Move it to `~/.codex/zerog.config.toml` |
| `The upstream provider rejected the request` (Kimi + Claude) | Kimi sends `context_management` | Add `[thinking] keep = "off"` |
| `API Error: 400 The upstream provider rejected the request` (Claude Code) | Claude Code sends beta features 0G rejects | Set `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` |
| `429 rate_limit_exceeded` | Too many requests | Wait for the `Retry-After` time, then retry |
| 404 on `pc.0g.ai/v1/...` | Dashboard URL used as the API | Use `https://router-api.0g.ai/v1` |

[↑ Back to contents](#contents)

## Saving tokens

Coding agents use more tokens than chat because they re-send the whole conversation on every step. In testing, a one-word Codex reply cost 12,609 tokens, all of it Codex's own instructions and tool list. A short real task cost 620,913 tokens, about 90% of them cached repeats.

- **Start fresh between tasks** with `/new` (`/clear` in Claude Code), and use `/compact` when a session gets long, so old file contents stop being re-sent.
- **Name the file and line** you want changed, so the agent reads one file instead of exploring.
- **Use a flash model for simple jobs** (`glm-5.3-flash`, `deepseek-v4-flash`, `qwen3.7-flash`) and save the big models for hard work.
- **Lower reasoning effort** for routine tasks; in Codex, add `model_reasoning_effort = "low"` to `~/.codex/zerog.config.toml`.

[↑ Back to contents](#contents)

## Sources

- [0G Router quickstart](https://docs.0g.ai/developer-hub/building-on-0g/compute-network/router/quickstart)
- [0G Router: Deposits & Billing](https://docs.0g.ai/developer-hub/building-on-0g/compute-network/router/account/deposits)
- [0G Router: Errors](https://docs.0g.ai/developer-hub/building-on-0g/compute-network/router/errors)
- [Kilo CLI docs](https://kilo.ai/docs/cli)
- [OpenCode: Providers](https://opencode.ai/docs/providers/)
- [Kimi Code: Providers and models](https://www.kimi.com/code/docs/en/kimi-code-cli/configuration/providers.html)
- [Claude Code: LLM gateway configuration](https://code.claude.com/docs/en/llm-gateway)

[↑ Back to contents](#contents)
