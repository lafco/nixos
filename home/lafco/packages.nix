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
  programs.eza.enable = true; # aliases por shell já vêm habilitados por padrão
  programs.bat.enable = true;
  programs.zoxide.enable = true;
}
