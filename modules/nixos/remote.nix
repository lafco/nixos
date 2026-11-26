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
#
# Celular: app do Tailscale + um cliente SSH (Blink, Termius, ShellFish) entram
# na tailnet e `ssh daily` cai no Tailscale SSH — identidade da tailnet, sem
# chave no celular. De lá o ambiente é o MESMO da janela do herdr-app, porque os
# terminais vivem no herdr-core (`hc`, socket em
# $XDG_RUNTIME_DIR/herdr-core/default.sock), não na janela:
#
#   ssh daily                    # picker: escolhe um terminal e anexa
#   ssh daily 'hc ls'            # espaços/abas/terminais e o agente de cada um
#   ssh daily 'hc read t2k'      # tela + histórico de um terminal
#   ssh daily 'hc run --bg pi'   # abre um agente novo, sem esperar
#   ssh daily 'herdr-app shot'   # PNG da janela (para ver o layout pelo celular)
#
# `hc` sobe o core sozinho se ele não estiver rodando, e o lingering
# (`users.users.lafco.linger` em hosts/daily) mantém o user manager vivo sem
# login: dá para chegar no celular com a sessão gráfica fechada. A janela do
# app não é necessária — ela só desenha o que o core já tem.
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
  # (O equivalente no GNOME está em home/modules/gnome.nix:
  # sleep-inactive-ac-type/sleep-inactive-battery-type = "nothing".)
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
