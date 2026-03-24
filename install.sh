#!/bin/bash
# Install claude-telegram-router
# Prerequisites: bun, claude (v2.1.80+)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dependencies..."
cd "$SCRIPT_DIR"
bun install --no-summary

echo ""
echo "Registering tg-session MCP server globally with Claude Code..."
claude mcp add -s user tg-session -- bun run "$SCRIPT_DIR/session-channel.ts"

echo ""
echo "Done! Now:"
echo ""
echo "  1. Configure your Telegram bot token:"
echo "     mkdir -p ~/.claude/channels/telegram"
echo "     echo 'TELEGRAM_BOT_TOKEN=your-token-here' > ~/.claude/channels/telegram/.env"
echo ""
echo "  2. Start the router:"
echo "     bun $SCRIPT_DIR/router.ts"
echo ""
echo "  3. Start a Claude session:"
echo "     SESSION_NAME=myproject claude --dangerously-load-development-channels server:tg-session"
echo ""
echo "  4. Pair on Telegram: DM your bot, get the code, run:"
echo "     /telegram:access pair <code>"
echo "     /telegram:access policy allowlist"
