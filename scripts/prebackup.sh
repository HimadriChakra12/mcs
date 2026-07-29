#!/usr/bin/env bash
# Pre-backup hook — add custom logic here (e.g. notify players)
# This file is optional and sourced by backup.sh if executable.
set -Eeuo pipefail

# Example: warn players in-game
# rcon-cli --host minecraft --port 25575 --password "${RCON_PASSWORD}" \
#   "say [Backup] Starting backup, brief lag possible..."
