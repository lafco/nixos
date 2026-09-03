# Máquina de USO DIÁRIO — NixOS + XFCE.
{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ./disko-config.nix ];

  networking.hostName = "daily";

  # UEFI + systemd-boot (disko cria a partição ESP).
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.lafco = {
    isNormalUser = true;
    description = "lafco";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.zsh; # zsh vem do home-manager
    initialPassword = "changeme"; # troque no primeiro login (passwd)
  };

  # Ambiente do usuário (home-manager em modo módulo) + perfil pessoal.
  home-manager.users.lafco = {
    imports = [ ../../home/lafco ../../home/profiles/personal.nix ];
  };

  # Segredos: decriptados pela chave SSH do host (veja docs/bootstrap.md).
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  system.stateVersion = "26.05"; # NÃO mude depois da primeira instalação
}
