# Editor: neovim (LazyVim) + runtimes que os plugins esperam.
# Os LSPs/formatters do nvim são instalados pelo Mason (config em
# ~/dotfiles/nvim), então não entram como pacotes aqui.
# (O Zed saiu: a config foi removida do repo de dotfiles junto com os
# pacotes/LSPs que existiam só para ele.)
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    neovim
    nodejs_22 # copilot, typescript-language-server etc.
    python3 # LSPs de python
    gcc # nvim-treesitter compila parsers em C
  ];
}
