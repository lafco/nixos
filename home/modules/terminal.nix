# Terminal: herdr (app desktop) + ghostty + zellij + clipboard
#
# O herdr-app é o terminal principal (Super+Return e favorito 1 do GNOME, ver
# home/modules/gnome.nix). Os pacotes estão em home/modules/ai.nix: o app, o
# `hc` (herdr-core, que hospeda os terminais) e o pi. O ghostty continua como
# alternativa, lendo a config equivalente de ~/dotfiles/ghostty (symlink em
# dotfiles.nix).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ghostty
    zellij

    # clipboard: Wayland e X11 (xwayland)
    wl-clipboard
    xclip
  ];
}
