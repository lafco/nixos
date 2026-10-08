# Base comum a TODAS as máquinas NixOS (daily e server).
{ inputs, pkgs, ... }:
{
  # Overlays compartilhados (pkgs.unstable.*) — definidos em lib/overlays.nix.
  nixpkgs.overlays = import ../../lib/overlays.nix { inherit inputs; };

  # obsidian/ankama-launcher (apps do home/modules) são unfree.
  nixpkgs.config.allowUnfree = true;

  # Necessário para usar este repo (flakes).
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Limpeza automática de gerações antigas.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  i18n.defaultLocale = "en_US.UTF-8";
  # i18n.defaultLocale = "pt_BR.UTF-8"; # descomente se preferir

  time.timeZone = "America/Sao_Paulo"; # ajuste se necessário

  # Ferramentas básicas de sistema (as do usuário vêm via home-manager).
  environment.systemPackages = with pkgs; [ git curl wget ];

  # Docker + docker compose, nos dois hosts (daily e server).
  #
  # NÃO precisa de pacote separado para o compose: o pkgs.docker do nixpkgs é
  # compilado com composeSupport = true e traz o plugin em
  # libexec/docker/cli-plugins — `docker compose` funciona direto.
  #
  # Rootful (daemon como root). O usuário lafco entra no grupo "docker" para
  # usar docker/compose sem sudo. ⚠️ o grupo docker equivale a root no host
  # (dá para montar / dentro de um container) — não adicione outros usuários.
  virtualisation.docker.enable = true;
  users.users.lafco.extraGroups = [ "docker" ];
}
