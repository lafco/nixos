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

  # Shell de login: bashInteractive (o bashrc vem do repo de dotfiles em
  # ~/dotfiles). Precisa ser bashInteractive: o pkgs.bash "puro" do NixOS é
  # compilado sem readline e não tem os builtins complete/bind, quebrando o
  # bash-completion e o starship no .bashrc.
  users.users.lafco = {
    isNormalUser = true;
    description = "lafco";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.bashInteractive;
    initialPassword = "changeme"; # troque no primeiro login (passwd)
    # Mantém os serviços de usuário (ex.: herdr) rodando sem login —
    # equivalente declarativo de `loginctl enable-linger lafco`.
    linger = true;
  };

  # Arquivos já existentes são preservados antes de o Home Manager instalar
  # as versões declarativas do repositório.
  home-manager.backupFileExtension = "hm-backup";

  # O XFCE reescreve os XMLs do xfconf em runtime, então a cada switch o
  # arquivo vivo difere do declarativo e um novo .hm-backup seria criado em
  # cima do anterior (abortando a ativação). Com overwriteBackup, o backup
  # velho é substituído pelo novo em vez de falhar.
  home-manager.overwriteBackup = true;

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
