# Core compartilhado do usuário — módulos home-manager LOCAIS (home/modules),
# com os arquivos de configuração vindos do repo de dotfiles
# (github:lafco/config) via symlinks — single source of truth em ~/dotfiles
# (home/modules/dotfiles.nix).
#
# Importante: este core espera que o repo de dotfiles esteja clonado em
# ~/dotfiles — o instalador da ISO faz isso automaticamente; em outras
# máquinas: git clone https://github.com/lafco/config ~/dotfiles
{ ... }:
{
  imports = [
    ../modules/dotfiles.nix
    ../modules/shell.nix
    ../modules/git.nix
    ../modules/editor.nix
    ../modules/terminal.nix
    ../modules/dev.nix
    ./ssh.nix
  ];

  xdg = {
    enable = true;

    # Pastas padrão do usuário (XDG user dirs). Music, publicShare e
    # templates ficam desativadas: apontar para $HOME remove o atalho do
    # Thunar e impede que a pasta seja recriada.
    userDirs = {
      enable = true;
      createDirectories = true;

      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      pictures = "$HOME/Pictures";
      videos = "$HOME/Videos";

      music = "$HOME";
      publicShare = "$HOME";
      templates = "$HOME";

      # Pasta customizada (não é um XDG dir padrão).
      extraConfig = {
        XDG_PROJECTS_DIR = "$HOME/Projects";
      };
    };
  };

  # Versão do home-manager da primeira ativação — NÃO mude depois.
  home.stateVersion = "26.05";
}
