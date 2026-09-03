# Endurecimento e ajustes do servidor headless (SSH-only).
{ pkgs, ... }:
{
  # O NixOS abre a porta 22 no firewall automaticamente ao habilitar o openssh.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Proteção contra brute-force no SSH.
  services.fail2ban.enable = true;

  # Swap comprimido em RAM (ótimo para VPS pequenos).
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # Rede privada opcional (descomente se usar Tailscale):
  # services.tailscale.enable = true;

  # Atualizações automáticas (descomente se quiser):
  # system.autoUpgrade = {
  #   enable = true;
  #   allowReboot = false;
  # };
}
