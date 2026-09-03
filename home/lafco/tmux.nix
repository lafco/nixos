# Tmux com alguns sane defaults.
{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    shortcut = "a"; # prefixo Ctrl-a em vez de Ctrl-b
    baseIndex = 1;
    keyMode = "vi";
    mouse = true;
    terminal = "screen-256color";
    extraConfig = ''
      set -g status-position top
    '';
    plugins = with pkgs.tmuxPlugins; [ sensible ];
  };
}
