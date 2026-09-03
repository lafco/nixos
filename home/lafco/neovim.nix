# Neovim com o mínimo de sane defaults.
# Quer uma config completa em Nix depois? Olhe o nixvim:
#   https://github.com/nix-community/nixvim
{ ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    extraLuaConfig = ''
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.expandtab = true
      vim.opt.smartindent = true
      vim.opt.termguicolors = true
      vim.opt.mouse = "a"
    '';
  };

  home.sessionVariables.EDITOR = "nvim";
}
