# Terminal: wezterm + ghostty + zellij + clipboard
#
# Os dois terminais convivem: o wezterm continua sendo o padrão (Super+Return e
# favorites do GNOME, ver home/modules/gnome.nix); o ghostty entra para teste,
# lendo a config equivalente de ~/dotfiles/ghostty (symlink em dotfiles.nix).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    wezterm
    ghostty
    zellij

    # clipboard: Wayland e X11 (xwayland)
    wl-clipboard
    xclip
  ];
}
