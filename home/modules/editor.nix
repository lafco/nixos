{ pkgs, ... }:
{
  home.packages = with pkgs; [
    neovim
    nodejs_22 # copilot, typescript-language-server etc.
    python3 # LSPs de python
    gcc # nvim-treesitter compila parsers em C
  ];
}
