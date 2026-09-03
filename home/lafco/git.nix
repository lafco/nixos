# Git: identidade pessoal padrão (a identidade do trabalho é sobrescrita
# em home/profiles/work.nix).
{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "lafco"; # TODO: troque
        email = "lafco@example.com"; # TODO: troque
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # defaults declarados em settings."*" abaixo
    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
      "github.com" = {
        IdentityFile = "~/.ssh/id_ed25519";
      };
      # Chave específica para o git da empresa:
      # "git.empresa.com" = {
      #   IdentityFile = "~/.ssh/id_ed25519_work";
      # };
    };
  };
}
