# Symlinks para os dotfiles do repo (github:lafco/config) — single source of
# truth em ~/dotfiles. Editar no repo tem efeito imediato (sem rebuild), e o
# `dot stow` continua funcionando em máquinas não-Nix.
#
{ config, ... }:
let
  repo = "${config.home.homeDirectory}/dotfiles";
  link = rel: config.lib.file.mkOutOfStoreSymlink "${repo}/${rel}";
in
{
  home.file = {
    # shell
    ".bashrc".source = link "bash/.bashrc";
    ".bash_profile".source = link "bash/.bash_profile";
    ".aliases".source = link "bash/.aliases";
    ".functions".source = link "bash/.functions";

    # editor
    ".config/nvim".source = link "nvim/.config/nvim";

    # terminal
    ".config/ghostty".source = link "ghostty/.config/ghostty";
    ".config/zellij".source = link "zellij/.config/zellij";

    # shell tools
    ".config/starship.toml".source = link "starship/.config/starship.toml";
    ".config/atuin/config.toml".source = link "atuin/.config/atuin/config.toml";
    ".config/television".source = link "television/.config/television";

    # git
    ".config/gh-dash".source = link "gh-dash/.config/gh-dash";

    # IA
    ".pi/agent".source = link "pi/.pi/agent";
    # herdr-app: só o que é do usuário. O resto de ~/.config/herdr-app (view.json,
    # shared.json, icons/, frame/, mods/, data/, *.d.ts) é escrito pelo app e
    # seria lixo no checkout — por isso arquivo a arquivo, e não o diretório.
    ".config/herdr-app/settings.json".source = link "herdr-app/.config/herdr-app/settings.json";
    ".config/herdr-app/keys.json".source = link "herdr-app/.config/herdr-app/keys.json";

    # IDEs
    ".config/zed/settings.json".source = link "zed/.config/zed/settings.json";
    ".config/zed/keymap.json".source = link "zed/.config/zed/keymap.json";
  };
}
