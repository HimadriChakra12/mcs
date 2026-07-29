#!/usr/bin/env bash
set -Eeuo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[BACKUP]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERR]${NC} $*" >&2; }

BACKUP_FILE="/backups/latest.tar.zst"
MANIFEST="/backups/manifest.json"
DATA_DIR="/data"
WORLDS=("world" "world_nether" "world_the_end")
TOOL_VERSION="1.0.0"

# ── Pre-backup hook ────────────────────────────────────────────────────────────
[[ -x /scripts/prebackup.sh ]] && bash /scripts/prebackup.sh

# ── Save-all via RCON ─────────────────────────────────────────────────────────
log "Sending save-all flush to server..."
rcon-cli --host minecraft --port 25575 --password "${RCON_PASSWORD}" \
  "save-all flush" 2>/dev/null || warn "RCON unavailable, skipping save-all"

sleep 3  # allow flush to complete

# ── Detect Minecraft version from version_manifest ────────────────────────────
MC_VERSION=$(cat /data/version.json 2>/dev/null | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "unknown")
SERVER_TYPE="PAPER"

# ── Compress world data ────────────────────────────────────────────────────────
log "Compressing world data..."
DIRS=()
for w in "${WORLDS[@]}"; do
  [[ -d "${DATA_DIR}/${w}" ]] && DIRS+=("${w}")
done

if [[ ${#DIRS[@]} -eq 0 ]]; then
  err "No world directories found in ${DATA_DIR}!"
  exit 1
fi

cd "${DATA_DIR}"
tar --use-compress-program="zstd -T0 -3" \
    -cf "${BACKUP_FILE}" \
    "${DIRS[@]}"

# ── SHA256 + manifest ─────────────────────────────────────────────────────────
SHA256=$(sha256sum "${BACKUP_FILE}" | awk '{print $1}')
SIZE=$(stat -c%s "${BACKUP_FILE}")
CREATED=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "${MANIFEST}" <<EOF
{
  "version": 1,
  "created": "${CREATED}",
  "minecraft_version": "${MC_VERSION}",
  "server_type": "${SERVER_TYPE}",
  "size": ${SIZE},
  "sha256": "${SHA256}",
  "backup_tool_version": "${TOOL_VERSION}"
}
EOF

ok "Backup complete: $(( SIZE / 1024 / 1024 ))MB | sha256=${SHA256:0:12}..."

# ── Optional Discord notification ──────────────────────────────────────────────
if [[ -n "${DISCORD_WEBHOOK:-}" ]]; then
  curl -sf -X POST "${DISCORD_WEBHOOK}" \
    -H "Content-Type: application/json" \
    -d "{\"content\":\"✅ Minecraft backup done — ${CREATED} | $(( SIZE/1024/1024 ))MB\"}" \
    || warn "Discord webhook failed"
fi

# ── Optional Git auto-push ─────────────────────────────────────────────────────
if [[ "${GIT_AUTO_PUSH:-false}" == "true" ]]; then
  REPO_ROOT=$(git -C /backups rev-parse --show-toplevel 2>/dev/null || true)
  if [[ -n "${REPO_ROOT}" ]]; then
    git -C "${REPO_ROOT}" add backups/latest.tar.zst backups/manifest.json
    git -C "${REPO_ROOT}" commit -m "backup: ${CREATED}" --allow-empty
    git -C "${REPO_ROOT}" push && ok "Git push complete" || warn "Git push failed"
  else
    warn "GIT_AUTO_PUSH=true but no git repo found"
  fi
fi

# ── Post-backup hook ───────────────────────────────────────────────────────────
[[ -x /scripts/postbackup.sh ]] && bash /scripts/postbackup.sh

exit 0
