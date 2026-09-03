#!/usr/bin/env bash
# Aplica a configuração no servidor remoto (requer sua chave SSH no servidor).
#
# Uso: ./scripts/deploy-server.sh <host-ou-ip>
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Uso: $0 <host-ou-ip>" >&2
  exit 1
fi

exec nixos-rebuild switch \
  --flake ".#server" \
  --target-host "root@$1" \
  --use-remote-sudo
