#!/usr/bin/env bash
# Super+Return: abre o wezterm rodando o herdr (AI workspace manager);
# se já houver uma janela aberta, só foca nela.
#
# O wezterm roda como um único processo (mux server), então `wezterm start`
# abriria uma aba nova na instância existente — o wmctrl cuida de focar a
# janela em vez de abrir outra.
set -euo pipefail

# O daemon de keybinds do XFCE herda o PATH da sessão gráfica; garante os
# caminhos comuns por segurança.
export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:$HOME/.local/bin:/run/current-system/sw/bin:$PATH"

# Foca a janela existente (WM_CLASS do wezterm = org.wezfurlong.wezterm,
# conforme StartupWMClass do .desktop oficial). O fallback por título é
# para o caso de a classe mudar em versões futuras.
if command -v wmctrl >/dev/null 2>&1; then
  wmctrl -x -a org.wezfurlong.wezterm 2>/dev/null && exit 0
  wmctrl -a wezterm 2>/dev/null && exit 0
fi

exec wezterm start -- herdr
