# Add to ~/.zshrc, then run: claude-0g
# Plain `claude` keeps using your normal Anthropic login.
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
