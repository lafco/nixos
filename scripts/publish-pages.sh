#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# Publica a URL curta do instalador: https://lafco.github.io/i
#
# Copia o conteúdo de pages/ (i, .nojekyll, index.html) para o repo PÚBLICO
# lafco/lafco.github.io e faz push. O GitHub Pages publica a branch main
# desse repo automaticamente — nada mais a configurar.
#
# Pré-requisito (uma única vez): crie o repo VAZIO "lafco.github.io" no
# GitHub (público, sem README): https://github.com/new
#
# Uso:
#   ./scripts/publish-pages.sh
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

REPO=git@github.com:lafco/lafco.github.io.git
SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/../pages" && pwd)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if ! git clone --depth 1 "$REPO" "$tmp"; then
  echo "ERRO: não consegui clonar $REPO." >&2
  echo "Crie o repo VAZIO 'lafco.github.io' no GitHub (público) e rode de novo:" >&2
  echo "  https://github.com/new" >&2
  exit 1
fi

# Substitui o conteúdo inteiro pelo de pages/ (preservando o .git)
cd "$tmp"
find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
cp -a "$SRC"/. .

git add -A
if git diff --cached --quiet; then
  echo "Nada a publicar — https://lafco.github.io/i já está em dia."
else
  git commit -m "sync: URL curta do instalador (lafco/nixos)"
  git push origin HEAD:main
  echo "Publicado! Teste: curl -Ls https://lafco.github.io/i | head"
fi
