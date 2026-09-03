# SSH: defaults explícitos + identidades.
# (O repo de dotfiles não declara SSH; fica aqui no nixos-repo.)
{ ... }:
{
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
