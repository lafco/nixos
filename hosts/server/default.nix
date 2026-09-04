# Servidor headless MÍNIMO para desenvolvimento (SSH-only).
{ pkgs, lib, ... }:
{
  # local.nix é opcional e específico da máquina (gerado pelo instalador da
  # ISO em install/install-iso.sh; não versionado). Sobrescreve hostname,
  # disco (disko) e usuário/senha locais.
  imports =
    [ ./hardware-configuration.nix ./disko-config.nix ]
    ++ lib.optional (builtins.pathExists ./local.nix) ./local.nix;

  networking.hostName = "server";

  # VPS típico: BIOS + GRUB.
  # O disco NÃO precisa ser listado aqui: a partição EF02 do disko-config.nix
  # faz o disko preencher boot.loader.grub.devices automaticamente.
  boot.loader.grub.enable = true;

  users.users.lafco = {
    isNormalUser = true;
    description = "lafco";
    extraGroups = [ "wheel" ];
    # shell = pkgs.zsh; # descomente para usar zsh no login do servidor
    shell = pkgs.bashInteractive; # evita os erros de complete/bind do pkgs.bash sem readline
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

  # Segredos (sops-nix): só ativa quando secrets/secrets.yaml existir.
  # Crie o arquivo (docs/bootstrap.md) e rode um rebuild para habilitar.
  # Decriptação: pela chave SSH do próprio host.
  sops = lib.mkIf (builtins.pathExists ../../secrets/secrets.yaml) {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  system.stateVersion = "26.05"; # NÃO mude depois da primeira instalação
}
