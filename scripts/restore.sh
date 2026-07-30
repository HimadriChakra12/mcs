#!/usr/bin/env bash
set -Eeuo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[RESTORE]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
err()  { echo -e "${RED}[ERR]${NC} $*" >&2; exit 1; }

BACKUP_FILE="backups/latest.tar.zst"
MANIFEST="backups/manifest.json"
DATA_DIR="data"

[[ -f "${BACKUP_FILE}" ]] || err "No backup found at ${BACKUP_FILE}"
[[ -f "${MANIFEST}" ]]   || err "No manifest found at ${MANIFEST}"

# ── Verify SHA256 ──────────────────────────────────────────────────────────────
log "Verifying archive integrity..."
EXPECTED=$(grep -o '"sha256": *"[^"]*"' "${MANIFEST}" | grep -o '[a-f0-9]\{64\}')
ACTUAL=$(sha256sum "${BACKUP_FILE}" | awk '{print $1}')
[[ "${EXPECTED}" == "${ACTUAL}" ]] || err "SHA256 mismatch! Backup may be corrupt."
ok "Checksum verified"

# ── Confirm ────────────────────────────────────────────────────────────────────
echo -e "${YELLOW}This will REPLACE your current world data. Continue? [y/N]${NC}"
read -r confirm
[[ "${confirm}" =~ ^[Yy]$ ]] || { log "Aborted."; exit 0; }

# ── Stop server ────────────────────────────────────────────────────────────────
log "Stopping minecraft container..."
docker compose stop minecraft

# ── Remove current world data ──────────────────────────────────────────────────
log "Removing old world directories..."
for w in world world_nether world_the_end; do
  rm -rf "${DATA_DIR:?}/${w}"
done

# ── Extract ───────────────────────────────────────────────────────────────────
log "Extracting backup..."
zstd -d -c "${BACKUP_FILE}" | tar -xf - -C "${DATA_DIR}/"

ok "World data restored from $(grep -o '"created":"[^"]*"' "${MANIFEST}" | cut -d'"' -f4)"

# ── Restart ───────────────────────────────────────────────────────────────────
log "Starting minecraft container..."
docker compose start minecraft
ok "Server is back online."
