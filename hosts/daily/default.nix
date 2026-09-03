# Máquina de USO DIÁRIO — NixOS + XFCE.
{ pkgs, lib, ... }:
{
  imports = [ ./hardware-configuration.nix ./disko-config.nix ];

  networking.hostName = "daily";

  # UEFI + systemd-boot (disko cria a partição ESP).
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # zsh como shell de login também no nível do sistema (assertion do NixOS).
  programs.zsh.enable = true;

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

  # Segredos (sops-nix): só ativa quando secrets/secrets.yaml existir.
  # Crie o arquivo (docs/bootstrap.md) e rode um rebuild para habilitar.
  # Decriptação: pela chave SSH do próprio host.
  sops = lib.mkIf (builtins.pathExists ../../secrets/secrets.yaml) {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  system.stateVersion = "26.05"; # NÃO mude depois da primeira instalação
}
