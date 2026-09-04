#!/usr/bin/env bash
# Sincroniza a configuração do XFCE da máquina viva (~/.config/xfce4) para
# o repo (home/modules/xfce/).
#
# Fluxo: ajuste pela GUI → rode este script → revise o diff (git diff) → commite.
#
# Ajustes aplicados na cópia (de propósito):
#   • wallpaper: o caminho do /nix/store (quebra a cada atualização do
#     xfdesktop) vira o caminho gerenciado ~/.config/xfce4/backgrounds/ e o
#     arquivo é copiado para o repo;
#   • ícones: Net/IconThemeName é forçado para Papirus-Dark (tema do repo).
set -euo pipefail

cd "$(dirname "$0")/.."

LIVE="$HOME/.config/xfce4"
REPO="home/modules/xfce"

mkdir -p "$REPO/panel/launcher-2" "$REPO/panel/launcher-7" "$REPO/backgrounds"

# Canais xfconf (só *.xml — ignora os backups .hm-backup do home-manager).
cp "$LIVE"/xfconf/xfce-perchannel-xml/*.xml "$REPO"/

# Launchers do painel.
cp "$LIVE"/panel/launcher-2/*.desktop "$REPO/panel/launcher-2/" 2>/dev/null || true
cp "$LIVE"/panel/launcher-7/*.desktop "$REPO/panel/launcher-7/" 2>/dev/null || true

# Wallpaper gerenciado.
bg=$(grep -o '<property name="last-image" type="string" value="[^"]*"' "$REPO/xfce4-desktop.xml" | sed 's/.*value="//;s/"$//')
case "$bg" in
  /nix/store/*-xfdesktop*/share/backgrounds/*)
    name=$(basename "$bg")
    cp "$bg" "$REPO/backgrounds/$name"
    sed -i "s|$bg|/home/lafco/.config/xfce4/backgrounds/$name|" "$REPO/xfce4-desktop.xml"
    ;;
  *)
    echo "aviso: wallpaper não está em /nix/store — verifique $bg" >&2
    ;;
esac

# Ícones: garante o tema do repo mesmo que a GUI tenha trocado o valor.
sed -i 's|<property name="IconThemeName" type="string" value="[^"]*"/>|<property name="IconThemeName" type="string" value="Papirus-Dark"/>|' \
  "$REPO/xsettings.xml"

echo "OK: XFCE sincronizado para $REPO/. Revise com git diff e commite."
