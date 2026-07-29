#!/usr/bin/env bash
# Checks if the Minecraft server process is alive and responding via RCON
set -Eeuo pipefail

rcon-cli --host localhost --port 25575 --password "${RCON_PASSWORD:-changeme}" \
  "list" > /dev/null 2>&1
