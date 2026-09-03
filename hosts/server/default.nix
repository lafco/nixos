# Servidor headless MÍNIMO para desenvolvimento (SSH-only).
{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ./disko-config.nix ];

  networking.hostName = "server";

  # VPS típico: BIOS + GRUB. Ajuste o device conforme o provedor.
  boot.loader.grub = {
    enable = true;
    devices = [ "/dev/sda" ]; # /dev/vda em KVM/Proxmox, /dev/nvme0n1 em bare metal
  };

  users.users.lafco = {
    isNormalUser = true;
    description = "lafco";
    extraGroups = [ "wheel" ];
    # shell = pkgs.zsh; # descomente para usar zsh no login do servidor
    initialPassword = "changeme"; # troque no primeiro login (passwd)
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAA... seu-comentario" # TODO: cole sua chave pública aqui
    ];
  };

  # Sem senha para sudo (login já é só por chave SSH).
  security.sudo.wheelNeedsPassword = false;

  # Ambiente do usuário no servidor (home-manager em modo módulo) + perfil enxuto.
  home-manager.users.lafco = {
    imports = [ ../../home/lafco ../../home/profiles/server.nix ];
  };

  # Segredos: decriptados pela chave SSH do host (veja docs/bootstrap.md).
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  system.stateVersion = "26.05"; # NÃO mude depois da primeira instalação
}
