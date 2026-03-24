<div align="center">

# Claude Code Multi-Session Channels

**Run multiple Claude Code sessions and control them all from one Telegram bot.**

Switch between sessions with `/switch`, send voice notes with automatic transcription, approve tool permissions remotely — all from Telegram.

Built on the [MCP channel protocol](https://code.claude.com/docs/en/channels-reference).

</div>

---

## Features

| Feature | Details | Status |
|---------|---------|--------|
| **Multi-session routing** | Run multiple Claude Code sessions, switch between them with `/switch` | Done |
| **Full channel experience** | Reply tools, typing indicators, emoji reactions, message editing | Done |
| **Permission relay** | Approve/deny Claude's tool use remotely via inline buttons | Done |
| **Voice transcription** | Voice notes transcribed automatically via Groq Whisper | Done |
| **File attachments** | Send photos, documents, audio, video — receive files back | Done |
| **Auto-reconnect** | Sessions re-register automatically if the router restarts | Done |
| **Dead session detection** | Stale sessions are reaped every 15 seconds | Done |
| **Sender gating** | Reuses the official plugin's allowlist — only you can message the bot | Done |

## How it works

```
Telegram ──> Router (standalone bot, port 8799)
                 |  HTTP (localhost)
           +─────+─────+
      Session A   Session B   Session C
      (MCP server, random port each)
           |          |          |
      Claude A   Claude B   Claude C
      ~/project1 ~/project2 ~/project3
```

| Component | File | Role |
|-----------|------|------|
| **Router** | `router.ts` | Standalone process. Polls Telegram, handles `/sessions` and `/switch`, forwards messages to the active session via HTTP |
| **Session channel** | `session-channel.ts` | MCP channel server spawned by Claude Code. Registers with the router, receives messages, exposes reply/react/edit tools |

## Prerequisites

- [Bun](https://bun.sh) runtime
- [Claude Code](https://claude.com/claude-code) v2.1.80+
- A Telegram bot token from [@BotFather](https://t.me/BotFather)

### First-time setup: pair your Telegram account

The official Telegram channel plugin must be set up **once** to create your bot and pair your account. Follow the [Claude Code channels guide](https://code.claude.com/docs/en/channels):

1. Install the plugin: `/plugin install telegram@claude-plugins-official`
2. Configure your token: `/telegram:configure <your-bot-token>`
3. Start with channels: `claude --channels plugin:telegram@claude-plugins-official`
4. Pair your account: DM the bot, get the code, run `/telegram:access pair <code>`
5. Lock it down: `/telegram:access policy allowlist`

Once pairing is complete, you can disable the official plugin and use this multi-session router instead.

## Setup

### 1. Disable the official Telegram plugin

In `~/.claude/settings.json`, set:

```json
"enabledPlugins": {
  "telegram@claude-plugins-official": false
}
```

### 2. Clone and install

```bash
git clone https://github.com/Agostinopisani19/claude-code-multisession-channels.git
cd claude-code-multisession-channels
bash install.sh
```

Or manually:

```bash
bun install
claude mcp add -s user tg-session -- bun run "$(pwd)/session-channel.ts"
```

### 3. Start the router

```bash
bun router.ts
```

You should see:

```
router: HTTP server on port 8799
router: polling as @your_bot
```

### 4. Start Claude Code sessions

Open a separate terminal for each session. Navigate to your project directory, then start Claude with a session name:

```bash
cd ~/project1
SESSION_NAME=project1 claude --dangerously-load-development-channels server:tg-session
```

```bash
cd ~/project2
SESSION_NAME=project2 claude --dangerously-load-development-channels server:tg-session
```

If you're already in the directory you want, just run the `SESSION_NAME=... claude ...` command directly.

> **Note:** Session names cannot contain spaces. Use dashes or underscores (e.g., `my-project`, `my_project`).

## Telegram commands

| Command | Description |
|---------|-------------|
| `/sessions` | List all connected sessions with active indicator |
| `/switch <name>` | Switch which session receives your messages |
| `/status` | Check your pairing state |
| `/help` | Show available commands |

Regular messages are routed to whichever session is active. The first session to connect becomes the default.

## Configuration

### Environment variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SESSION_NAME` | No | basename of cwd | Display name for the session |
| `ROUTER_PORT` | No | `8799` | HTTP port the router listens on |
| `TELEGRAM_BOT_TOKEN` | **Yes** | — | Bot token from BotFather |
| `GROQ_API_KEY` | No | — | Enables voice transcription |

### Token location

The bot token is read from `~/.claude/channels/telegram/.env` (created during the official plugin setup):

```env
TELEGRAM_BOT_TOKEN=123456789:AAH...
```

### Voice transcription (optional)

Voice notes and audio messages can be automatically transcribed before forwarding to Claude. This requires a free [Groq](https://console.groq.com) API key.

1. Get an API key at https://console.groq.com/keys
2. Save it:
   ```bash
   echo 'GROQ_API_KEY=your-key-here' > ~/.claude/telegram-router/.env
   ```
3. Restart the router

Without the key, voice notes are forwarded as `(voice message)` — Claude won't be able to hear them.

## Architecture

The router and session channels communicate over localhost HTTP:

| Direction | Endpoint | Purpose |
|-----------|----------|---------|
| Router -> Session | `POST /message` | Forward a Telegram message |
| Router -> Session | `POST /permission_verdict` | Forward user's allow/deny decision |
| Session -> Router | `POST /register` | Register or re-register a session |
| Session -> Router | `POST /unregister` | Remove a session on shutdown |
| Session -> Router | `POST /reply` | Send a message to Telegram |
| Session -> Router | `POST /react` | Add emoji reaction |
| Session -> Router | `POST /edit` | Edit a previously sent message |
| Session -> Router | `POST /download_attachment` | Download a file from Telegram |
| Session -> Router | `POST /permission_request` | Forward a permission prompt to Telegram |
| Session -> Router | `POST /typing` | Show typing indicator |

## Compatibility with official plugin

This router **replaces** the official Telegram channel plugin — you cannot run both at the same time (they'd fight over the same bot token).

| Mode | How to run |
|------|-----------|
| **Multi-session** | Disable official plugin, use this router |
| **Single-session** | Stop the router, re-enable the official plugin with `claude --channels plugin:telegram@claude-plugins-official` |

## License

MIT
