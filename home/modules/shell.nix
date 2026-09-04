# Shell: bash + ferramentas TUI (ex-mise)
# Os inits (starship, zoxide, atuin, tv) já estão em bash/.bashrc do repo.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # prompt + navegação
    starship
    zoxide
    atuin
    bash-preexec # atuin no bash precisa dele (ou ble.sh) para capturar comandos
    television

    # cat/ls/find/grep modernos
    bat
    eza
    fd
    ripgrep

    # file manager TUI (o thunar continua como GUI no XFCE)
    xplr

    # sistema
    btop

    # usados por bash/.functions e bash/.aliases
    jq
    lsof

    # devenv + direnv (ambientes por projeto)
    direnv
    nix-direnv
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Caminho do bash-preexec usado no bash/.bashrc do repo de dotfiles.
  home.sessionVariables.BASH_PREEXEC_SH = "${pkgs.bash-preexec}/share/bash/bash-preexec.sh";
}
