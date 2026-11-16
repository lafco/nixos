# Stack de torrents (só na daily): qBittorrent headless (web UI) + Prowlarr
# (gerenciador de indexers/trackers). Ambos rodam como serviço. A WebUI e o
# Prowlarr escutam em todas as interfaces, mas o firewall só abre a porta de
# BT (51413) — 8080 e 9696 ficam inacessíveis de fora.
#
# Acesso:
#   qBittorrent: http://localhost:8080  (usuário `admin`; a senha NÃO fica no
#     git — o hash PBKDF2 vive cifrado em secrets/secrets.yaml como
#     `qbittorrent/webui-password-hash` e é injetado no conf a cada start).
#     Para trocar a senha: gerar o hash e gravar no sops.
#       python3 - <<'EOF'
#       import base64, hashlib, os
#       salt = os.urandom(16)
#       dk = hashlib.pbkdf2_hmac('sha512', b'NOVA_SENHA', salt, 100000, 64)
#       print('@ByteArray(%s:%s)' % (base64.b64encode(salt).decode(),
#                                    base64.b64encode(dk).decode()))
#       EOF
#     e gravar no sops (o valor é JSON, daí as aspas duplas dentro das simples):
#       sops set secrets/secrets.yaml '["qbittorrent"]["webui-password-hash"]' '"@ByteArray(...)"'
#     depois `nixos-rebuild switch` para o ExecStartPre reescrever o conf.
#   Prowlarr: http://localhost:9696 (configure uma conta na primeira visita)
#
# Porta de BT fixa (51413, TCP+UDP) para aceitar conexões de entrada. Sem
# port forward no roteador (WAN 51413 -> 192.168.0.72) isso só ajuda na LAN;
# com o forward, melhora a taxa e o número de peers. A WebUI continua fechada.
#
# Integração: no Prowlarr, Settings → Apps → adicione o qBittorrent para ele
# sincronizar os indexers automaticamente no cliente.
# Acesso remoto depois: SSH tunnel (ssh -L 8080:localhost:8080 daily) ou
# Tailscale — não abra a 8080 direto na internet.
#
# Obs.: as chaves de preferência do qBittorrent 5.x ficam em [BitTorrent]
# com prefixo `Session\` (SavePath, TempPath, Port). As antigas
# `[Preferences] Downloads\*` do 4.x foram removidas deste módulo.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Marcador que o ExecStartPre troca pela hash vinda do sops. Não é segredo:
  # o valor cifrado está em secrets/secrets.yaml.
  webuiPasswordPlaceholder = "@@WEBUI_PASSWORD_HASH@@";
  webuiPasswordSecret = config.sops.secrets."qbittorrent/webui-password-hash";
  qbittorrentConf = "/var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf";

  downloadDir = "/var/lib/qbittorrent/Downloads";
  incompleteDir = "${downloadDir}/incomplete";
in
{
  services.qbittorrent = {
    enable = true;
    webuiPort = 8080;
    torrentingPort = 51413;
    serverConfig = {
      LegalNotice.Accepted = true; # pula o aviso legal do 1º acesso
      BitTorrent.Session = {
        Port = 51413;
        DefaultSavePath = downloadDir;
        TempPathEnabled = true;
        TempPath = incompleteDir;
      };
      Preferences.WebUI = {
        Username = "admin";
        Password_PBKDF2 = webuiPasswordPlaceholder;
      };
    };
  };

  # A hash da senha da WebUI vem do sops (dono qbittorrent para o serviço
  # conseguir ler). Sem ela o serviço não sobe, de propósito: falha alto
  # em vez de subir com a senha temporária.
  sops.secrets."qbittorrent/webui-password-hash" = {
    owner = "qbittorrent";
    group = "qbittorrent";
  };

  # O módulo instala o conf a partir do store (mkIf serverConfig != {}) com o
  # marcador; este ExecStartPre roda depois e troca o marcador pela hash.
  # Roda a cada start porque o conf é reescrito inteiro a cada start.
  systemd.services.qbittorrent.serviceConfig.ExecStartPre = lib.mkAfter [
    (pkgs.writeShellScript "qbittorrent-webui-password" ''
      set -eu
      conf=${qbittorrentConf}
      hash="$(${pkgs.coreutils}/bin/cat ${webuiPasswordSecret.path})"
      ${pkgs.gnused}/bin/sed -i "s|${webuiPasswordPlaceholder}|$hash|g" "$conf"
      if ${pkgs.gnugrep}/bin/grep -q '${webuiPasswordPlaceholder}' "$conf"; then
        echo "erro: marcador da senha não substituído em $conf" >&2
        exit 1
      fi
    '')
  ];

  # Pasta de downloads (mude aqui se um dia usar um disco externo).
  # 2770 + setgid: o `lafco` (grupo qbittorrent) pode ler e apagar os
  # arquivos prontos sem sudo.
  systemd.tmpfiles.rules = [
    "d ${downloadDir} 2770 qbittorrent qbittorrent -"
    "d ${incompleteDir} 2770 qbittorrent qbittorrent -"
  ];
  users.users.lafco.extraGroups = [ "qbittorrent" ];

  # Só a porta de BT é liberada (TCP para peers, UDP para DHT/µTP).
  # openFirewall do módulo abriria também a 8080, por isso não é usado.
  networking.firewall.allowedTCPPorts = [ 51413 ];
  networking.firewall.allowedUDPPorts = [ 51413 ];

  services.prowlarr = {
    enable = true;
    # openFirewall = true; # descomente p/ acessar de outra máquina da rede
  };
}
