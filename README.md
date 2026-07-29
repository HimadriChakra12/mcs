# 🎮 Minecraft Server

Docker-based Paper Minecraft server with automatic backups, Playit.gg public access, and Git versioning.

---

## Requirements

- Docker + Docker Compose v2
- `zstd` on host (only needed for `make restore`)
- Git (optional, for auto-push)

---

## Installation

```bash
git clone <your-repo-url> minecraft-server
cd minecraft-server
cp .env.example .env
# Edit .env with your settings
make up
```

The server starts, downloads Paper, and is ready in ~60 seconds. Check `make logs`.

---

## First Startup

1. Copy and edit `.env`:
   ```bash
   cp .env.example .env
   nano .env   # set MC_MEMORY, RCON_PASSWORD, TZ, etc.
   ```
2. Start:
   ```bash
   make up
   ```
3. Watch logs until you see `Done`:
   ```bash
   make logs
   ```
4. Connect in Minecraft: `localhost:25565`

---

## Changing Versions

Edit `.env`:
```env
MC_VERSION=1.21.1
```
Then:
```bash
make update
```
> ⚠ Always back up before changing versions: `make backup`

---

## Backups

Backups run **automatically every hour** (configurable via `BACKUP_INTERVAL` in `.env`).

Manual backup:
```bash
make backup
```

What gets backed up:
- `world/`, `world_nether/`, `world_the_end/`
- Compressed with zstd into `backups/latest.tar.zst`
- SHA256 recorded in `backups/manifest.json`

What is **excluded**: logs, cache, plugins, configs (configs are in Git).

### Git Auto-push

Set in `.env`:
```env
GIT_AUTO_PUSH=true
```
The backup container will `git commit` and `git push` after each backup.

### Discord Notifications

```env
DISCORD_WEBHOOK=https://discord.com/api/webhooks/...
```

---

## Restoring

```bash
make restore
```

This will:
1. Verify the `latest.tar.zst` checksum
2. Stop the server
3. Wipe current world data
4. Extract the backup
5. Restart the server

> To restore from an older backup: replace `backups/latest.tar.zst` with your archive and update `manifest.json` SHA256, then run `make restore`.

---

## Updating the Server

```bash
make backup    # always back up first
make update    # pulls latest image, recreates containers
```

---

## Public Access via Playit.gg

Friends can join from anywhere — no port forwarding required.

### One-time Setup

1. Create a free account at [playit.gg](https://playit.gg)
2. In the Playit dashboard → **Agents** → **Add Agent**
3. Copy the **secret key** shown
4. Add it to your `.env`:
   ```env
   PLAYIT_SECRET=your_secret_key_here
   ```
5. Start with the public profile:
   ```bash
   make public
   ```
6. In the Playit dashboard → **Tunnels** → **Add Tunnel**
   - Type: **Minecraft Java**
   - Local address: `minecraft:25565`
7. Your server address will appear, e.g. `abc123.at.playit.gg`

### Share with Friends

Give them the Playit hostname. They connect directly — no software needed on their end.

### Stopping the Tunnel (Keeping Server Up)

```bash
make public-down
```

### If the Token Changes

Update `PLAYIT_SECRET` in `.env` then:
```bash
docker compose restart playit
```

### Switching Tunnel Providers

The `playit` service is isolated in the `public` profile. To replace it:
1. Remove the `playit` service from `docker-compose.yml`
2. Add your new tunnel service (Tailscale, cloudflared, etc.) under the `public` profile
3. No other files need to change

---

## Makefile Reference

| Command | Description |
|---|---|
| `make up` | Start server only (local play) |
| `make public` | Start server + Playit tunnel |
| `make public-down` | Stop Playit, keep server running |
| `make down` | Stop everything |
| `make restart` | Restart Minecraft container |
| `make logs` | Follow server logs |
| `make shell` | Bash shell in server container |
| `make backup` | Manual backup now |
| `make restore` | Restore from latest backup |
| `make ps` | Container status |
| `make update` | Pull latest image + recreate |
| `make nuke` | ⚠ Delete all data (keeps backups) |

---

## Configuration Reference (`.env`)

| Variable | Default | Description |
|---|---|---|
| `MC_VERSION` | `LATEST` | Minecraft version |
| `MC_MEMORY` | `2G` | JVM heap size |
| `MAX_PLAYERS` | `20` | Max concurrent players |
| `MOTD` | `A Minecraft Server` | Server list message |
| `TZ` | `UTC` | Timezone |
| `RCON_PASSWORD` | `changeme` | RCON password (change this!) |
| `WHITELIST_ENABLED` | `false` | Enable whitelist |
| `WHITELIST` | *(empty)* | Comma-separated usernames |
| `OPS` | *(empty)* | Comma-separated op usernames |
| `BACKUP_INTERVAL` | `3600` | Seconds between auto-backups |
| `GIT_AUTO_PUSH` | `false` | Auto git push after backup |
| `DISCORD_WEBHOOK` | *(empty)* | Discord webhook URL |
| `PLAYIT_SECRET` | *(empty)* | Playit.gg secret key |

---

## Playing over Tailscale

If you prefer Tailscale over Playit:

1. Install Tailscale on both machines
2. Use `make up` (no tunnel needed)
3. Friends connect using your **Tailscale IP**: `100.x.x.x:25565`

---

## Troubleshooting

**Server won't start**
```bash
make logs   # look for EULA or memory errors
```

**Out of memory**
```
MC_MEMORY=4G   # increase in .env, then make restart
```

**Playit not connecting**
```bash
docker compose logs playit   # check token/auth errors
```

**Backup container crashes**
```bash
docker compose logs backup   # usually missing RCON or zstd
```

**World corrupt after crash**
```bash
make restore   # rolls back to last good backup
```

**Reset everything and start fresh**
```bash
make nuke
make up
```

---

## Project Structure

```
minecraft-server/
├── docker-compose.yml   # Service definitions
├── Makefile             # All common commands
├── .env.example         # Config template
├── .gitignore
├── README.md
├── config/              # Committed — server config, plugins list
├── backups/             # latest.tar.zst + manifest.json (committed)
├── data/                # Live world data (NOT committed)
└── scripts/             # backup, restore, healthcheck
```

---

## Git Strategy

Committed: everything in `config/`, `scripts/`, `backups/latest.tar.zst`, `backups/manifest.json`, and the project files.

Not committed: `data/` (live world — too large and changes constantly).

The repo grows over time as backup archives are committed. This is a deliberate tradeoff for simplicity.
