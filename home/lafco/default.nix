# Core compartilhado do usuário — usa os módulos home-manager do repo de
# dotfiles (github:lafco/config), mantendo ~/dotfiles como single source of
# truth (o dotfiles.nix de lá cria symlinks para ~/dotfiles/...).
#
# Importante: este core espera que o repo de dotfiles esteja clonado em
# ~/dotfiles — o instalador da ISO faz isso automaticamente; em outras
# máquinas: git clone https://github.com/lafco/config ~/dotfiles
{ inputs, ... }:
{
  imports = [
    (inputs.dotfiles + "/nixos/modules/home/dotfiles.nix")
    (inputs.dotfiles + "/nixos/modules/home/shell.nix")
    (inputs.dotfiles + "/nixos/modules/home/git.nix")
    (inputs.dotfiles + "/nixos/modules/home/editor.nix")
    (inputs.dotfiles + "/nixos/modules/home/terminal.nix")
    ./ssh.nix
  ];

  xdg.enable = true;

  # Versão do home-manager da primeira ativação — NÃO mude depois.
  home.stateVersion = "26.05";
}
