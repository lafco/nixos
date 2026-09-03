# Git: identidade pessoal padrão (a identidade do trabalho é sobrescrita
# em home/profiles/work.nix).
{ ... }:
{
  programs.git = {
    enable = true;
    userName = "lafco"; # TODO: troque
    userEmail = "lafco@example.com"; # TODO: troque
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";
    };
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        identityFile = "~/.ssh/id_ed25519";
      };
      # Chave específica para o git da empresa:
      # "git.empresa.com" = {
      #   identityFile = "~/.ssh/id_ed25519_work";
      # };
    };
  };
}
