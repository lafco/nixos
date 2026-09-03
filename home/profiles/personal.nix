# Perfil PESSOAL — usado na máquina de uso diário (NixOS "daily").
# O core (shell, git, nvim, tmux, direnv) já vem de home/lafco.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    mpv
    yt-dlp
  ];
}
