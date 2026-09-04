# Máquina de USO DIÁRIO — NixOS + XFCE.
{ pkgs, lib, ... }:
{
  # local.nix é opcional e específico da máquina (gerado pelo instalador da
  # ISO em install/install-iso.sh; não versionado). Sobrescreve hostname,
  # disco (disko) e usuário/senha locais.
  imports =
    [ ./hardware-configuration.nix ./disko-config.nix ]
    ++ lib.optional (builtins.pathExists ./local.nix) ./local.nix;

  networking.hostName = "daily";

  # UEFI + Limine (disko cria a partição ESP).
  boot.loader.systemd-boot.enable = false;
  boot.loader.limine = {
    enable = true;
    efiSupport = true;
    biosSupport = false;
    enableEditor = false;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Shell de login: bash (o bashrc vem do repo de dotfiles em ~/dotfiles).
  users.users.lafco = {
    isNormalUser = true;
    description = "lafco";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.bash;
    initialPassword = "changeme"; # troque no primeiro login (passwd)
  };

  # Arquivos já existentes são preservados antes de o Home Manager instalar
  # as versões declarativas do repositório.
  home-manager.backupFileExtension = "hm-backup";

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
