# Agentes de IA: pi (pi.dev) + herdr
# Ambos só existem no nixpkgs-unstable — vêm do overlay em lib/overlays.nix.
{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    unstable.pi-coding-agent # pi
    unstable.herdr # AI workspace manager
  ];

  # herdr "always-on": server headless sob o systemd user, iniciando no boot
  # via lingering (users.users.lafco.linger no host daily). Sobrevive a
  # logout/reboot; do celular, `herdr` só anexa à sessão existente.
  # ⚠️ Na primeira ativação, pare o server atual com `herdr server stop` antes
  # de `systemctl --user enable --now herdr` (libera o socket herdr.sock).
  systemd.user.services.herdr = {
    Unit = {
      Description = "Herdr headless server";
    };
    Service = {
      ExecStart = "${lib.getExe pkgs.unstable.herdr} server";
      Restart = "on-failure";
      RestartSec = "5";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
