# Acesso remoto: Tailscale + Tailscale SSH (sem abrir porta no roteador).
#
# - Tailscale: overlay WireGuard com NAT traversal/relay automático. A auth
#   key vem do sops (secrets/secrets.yaml → "tailscale/authkey"); com
#   authKeyFile, o tailscaled-autoconnect registra a máquina na tailnet e
#   aplica extraUpFlags automaticamente.
# - Tailscale SSH: o tailscaled atende a porta 22 do IP 100.x autenticando
#   pela identidade da tailnet (ACL do admin console) — não usa o sshd e não
#   exige chave SSH no celular.
# - OpenSSH local: fallback endurecido para acesso na LAN (não é exposto à
#   internet: a máquina fica atrás do NAT do roteador).
# - fail2ban: proteção contra brute-force no sshd da LAN.
{ config, ... }:
{
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale/authkey".path;
    # Habilita o servidor SSH do Tailscale no IP 100.x (persistente).
    extraUpFlags = [ "--ssh" ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.fail2ban.enable = true;

  # Máquina sempre alcançável: ignora ações de tampa/logind que suspendem.
  # (A suspensão por inatividade do XFCE é desativada em
  # home/modules/xfce/xfce4-power-manager.xml.)
  services.logind.settings = {
    "Login" = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
    };
  };

  # Auth key do Tailscale (criar em secrets/secrets.yaml).
  sops.secrets."tailscale/authkey" = { };
}
