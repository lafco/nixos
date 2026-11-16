#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# Bump do och (fork do OpenChamber) no pacote Nix:
#   1. dispara o workflow release-linux.yml no fork (builda o AppImage e
#      publica o release no GitHub Releases);
#   2. acompanha o run até terminar;
#   3. calcula o hash do AppImage novo (nix store prefetch-file);
#   4. atualiza `version` e `hash` em pkgs/och.nix.
#
# O owner/repo do fork são LIDOS de pkgs/och.nix — a config continua sendo a
# única fonte da verdade. O workflow sobrescreve os assets do release se ele
# já existir, então o script também serve para re-buildar a MESMA versão
# depois de mexer no fork (o hash muda, a versão não).
#
# Ctrl+C durante o build só interrompe a espera — o run continua no GitHub;
# reanexe com: gh run watch <id> -R <fork> --exit-status
#
# Pré-requisitos: gh autenticado (gh auth login), jq e nix no PATH.
#
# Uso:
#   ./scripts/och-bump.sh 2.7.3
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

# Caminho do pacote relativo ao script (independe do cwd de quem chamou).
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PKG_FILE="$REPO_ROOT/pkgs/och.nix"

usage() {
  echo "Uso: $0 <versão>   (ex.: $0 2.7.3)" >&2
  exit 1
}

if [ "$#" -ne 1 ]; then
  usage
fi

VERSION=$1
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERRO: versão inválida: $VERSION (esperado X.Y.Z)" >&2
  usage
fi

for cmd in gh jq nix; do
  if ! command -v "$cmd" >/dev/null; then
    echo "ERRO: $cmd não está no PATH." >&2
    exit 1
  fi
done

# Fork lido do próprio pacote (args owner/repo com default do callPackage).
OWNER=$(sed -n 's/^  owner ? "\(.*\)",$/\1/p' "$PKG_FILE")
REPO=$(sed -n 's/^  repo ? "\(.*\)",$/\1/p' "$PKG_FILE")
if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
  echo "ERRO: não achei owner/repo em $PKG_FILE" >&2
  exit 1
fi
FORK="$OWNER/$REPO"

# Id do run mais recente ANTES do dispatch — o novo run leva alguns segundos
# para aparecer na API, e sem essa referência o `gh run list --limit 1`
# devolveria um run antigo já terminado.
OLD_RUN_ID=$(gh run list -R "$FORK" --workflow=release-linux.yml --limit 1 \
  --json databaseId --jq '.[0].databaseId // empty' || true)

echo "→ Disparando release v$VERSION no $FORK (workflow release-linux.yml)…"
gh workflow run release-linux.yml -R "$FORK" -f "version=$VERSION"

RUN_ID=""
for _ in {1..30}; do
  RUN_ID=$(gh run list -R "$FORK" --workflow=release-linux.yml --limit 1 \
    --json databaseId --jq '.[0].databaseId // empty' || true)
  if [ -n "$RUN_ID" ] && [ "$RUN_ID" != "$OLD_RUN_ID" ]; then
    break
  fi
  sleep 5
done
if [ -z "$RUN_ID" ] || [ "$RUN_ID" = "$OLD_RUN_ID" ]; then
  echo "ERRO: o run novo não apareceu na API." >&2
  echo "Confira: gh run list -R $FORK --workflow=release-linux.yml" >&2
  exit 1
fi

echo "→ Acompanhando o run #$RUN_ID (Ctrl+C só interrompe a espera)…"
if ! gh run watch "$RUN_ID" -R "$FORK" --exit-status; then
  echo "ERRO: o run #$RUN_ID falhou." >&2
  echo "Veja: gh run view $RUN_ID -R $FORK --log-failed" >&2
  exit 1
fi

ASSET="OpenChamber-$VERSION-linux-x86_64.AppImage"
echo "→ Localizando o asset $ASSET no release v$VERSION…"
URL=$(gh release view "v$VERSION" -R "$FORK" --json assets \
  --jq ".assets[] | select(.name == \"$ASSET\") | .browser_download_url")

if [ -z "$URL" ]; then
  echo "ERRO: o asset $ASSET não está no release v$VERSION." >&2
  echo "O run terminou mas não publicou? Confira: gh release view v$VERSION -R $FORK" >&2
  exit 1
fi

echo "→ Calculando o hash (nix store prefetch-file — baixa o asset de novo)…"
HASH=$(nix store prefetch-file --json --hash-type sha256 "$URL" | jq -r .hash)

echo "→ Atualizando $PKG_FILE (version → $VERSION)…"
sed -i \
  -e "s/^  version = \"[0-9][0-9.]*\";$/  version = \"$VERSION\";/" \
  -e "s|^    hash = \"sha256-[A-Za-z0-9+/=]*\";$|    hash = \"$HASH\";|" \
  "$PKG_FILE"

if ! grep -q "^  version = \"$VERSION\";$" "$PKG_FILE" ||
  ! grep -q "^    hash = \"$HASH\";$" "$PKG_FILE"; then
  echo "ERRO: a substituição em $PKG_FILE não bateu — confira o arquivo." >&2
  exit 1
fi

cat <<EOF

Pronto! Atualizei pkgs/och.nix:
  version = "$VERSION"
  hash   = "$HASH"

Aplique com:
  nixos-rebuild switch --flake .#daily
EOF
