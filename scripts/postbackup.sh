#!/usr/bin/env bash
# Post-backup hook — add custom logic here (e.g. prune old copies, notify)
# This file is optional and sourced by backup.sh if executable.
set -Eeuo pipefail

# Example: notify players backup is done
# rcon-cli --host minecraft --port 25575 --password "${RCON_PASSWORD}" \
#   "say [Backup] Backup complete."
