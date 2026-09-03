# Pacotes de linha de comando comuns a todas as máquinas.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ripgrep
    fd
    fzf
    jq
    bat
    htop
    btop
    tree
    unzip
  ];

  programs.fzf.enable = true;
  programs.eza.enable = true;
  programs.eza.enableAliases = true;
  programs.bat.enable = true;
  programs.zoxide.enable = true;
}
