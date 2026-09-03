# Shell: zsh + starship + aliases.
{ ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      cat = "bat";
      g = "git";
      ".." = "cd ..";
    };
    initContent = ''
      export PATH="$PATH:$HOME/.local/bin"
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
    };
  };
}
