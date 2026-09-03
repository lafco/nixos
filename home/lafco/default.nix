# Configuração HOME base — compartilhada por TODAS as máquinas:
#  - daily  (NixOS, modo módulo, + profiles/personal.nix)
#  - server (NixOS, modo módulo, + profiles/server.nix)
#  - work   (Ubuntu/Debian, home-manager standalone, + profiles/work.nix)
#
# Cada máquina acrescenta apenas um "perfil" de home/profiles/.
{ ... }:
{
  imports = [
    ./packages.nix
    ./shell.nix
    ./git.nix
    ./neovim.nix
    ./tmux.nix
    ./direnv.nix
  ];

  # Deixa o home-manager gerenciar ~/.config e afins de forma limpa.
  xdg.enable = true;

  # Versão do home-manager da primeira ativação — NÃO mude depois.
  home.stateVersion = "26.05";
}
