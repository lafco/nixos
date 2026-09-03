# Base comum a TODAS as máquinas NixOS (daily e server).
{ pkgs, ... }:
{
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
}
