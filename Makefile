# ── minecraft-server Makefile ─────────────────────────────────────────────────
# Usage: make <target>
# Requires: docker compose v2, .env file (copy from .env.example)

DC      := docker compose
SERVER  := minecraft

.PHONY: up down restart logs shell backup restore ps nuke update public public-down help

## Start only the Minecraft server (default)
up:
	$(DC) up -d minecraft backup

## Start server + Playit tunnel (public access)
public:
	$(DC) --profile public up -d

## Stop the Playit tunnel, leave server running
public-down:
	$(DC) stop playit && $(DC) rm -f playit

## Stop all services
down:
	$(DC) down

## Restart the server
restart:
	$(DC) restart $(SERVER)

## Follow server logs
logs:
	$(DC) logs -f $(SERVER)

## Open a bash shell in the server container
shell:
	docker exec -it $(SERVER) bash

## Trigger a manual backup immediately
backup:
	docker exec minecraft-backup bash /scripts/backup.sh

## Restore world from latest.tar.zst
restore:
	bash scripts/restore.sh

## Show running container status
ps:
	$(DC) ps

## Pull latest images and recreate containers
update:
	$(DC) pull
	$(DC) up -d --force-recreate

## ⚠ DANGER: Wipe ALL data, containers, volumes (keeps backups)
nuke:
	@read -p "This deletes all server data. Type YES to confirm: " c; [ "$$c" = "YES" ] || exit 1
	$(DC) down -v
	rm -rf data/

## Show this help
help:
	@grep -E '^##' Makefile | sed 's/## //'
