# Stack de torrents (só na daily): qBittorrent headless (web UI) + Prowlarr
# (gerenciador de indexers/trackers). Ambos rodam como serviço e respondem
# só em localhost — o firewall não expõe nada (openFirewall = false).
#
# Acesso:
#   qBittorrent: http://localhost:8080
#     Sem senha fixada, o serviço gera uma TEMPORÁRIA a cada start — veja
#     em `journalctl -u qbittorrent` ("temporary password..."). Para fixar:
#     defina a senha na WebUI e copie o hash gerado
#     (/var/lib/qbittorrent/qBittorrent/config/qBittorrent.conf) para
#     Preferences.WebUI.Password_PBKDF2 aqui — senão o ExecStartPre
#     sobrescreve o conf e a senha da WebUI se perde no restart.
#   Prowlarr: http://localhost:9696 (configure uma conta na primeira visita)
#
# Integração: no Prowlarr, Settings → Apps → adicione o qBittorrent para ele
# sincronizar os indexers automaticamente no cliente.
# Acesso remoto depois: SSH tunnel (ssh -L 8080:localhost:8080 daily) ou
# Tailscale — não abra essas portas direto na internet.
{ ... }:
{
  services.qbittorrent = {
    enable = true;
    webuiPort = 8080;
    serverConfig = {
      LegalNotice.Accepted = true; # pula o aviso legal do 1º acesso
      Preferences = {
        Downloads = {
          SavePath = "/var/lib/qbittorrent/Downloads";
          TempPathEnabled = true;
        };
      };
    };
  };

  # Pasta de downloads (mude aqui se um dia usar um disco externo) e acesso
  # de leitura para o usuário lafco sem sudo.
  systemd.tmpfiles.rules = [
    "d /var/lib/qbittorrent/Downloads 0750 qbittorrent qbittorrent -"
  ];
  users.users.lafco.extraGroups = [ "qbittorrent" ];

  services.prowlarr = {
    enable = true;
    # openFirewall = true; # descomente p/ acessar de outra máquina da rede
  };
}
