# Perfil PESSOAL — usado na máquina de uso diário (NixOS "daily").
# Adiciona os módulos "pesados"/de desktop (apps gráficos + agentes de IA +
# keybinds/aparência do GNOME) que não fazem sentido nas outras máquinas.
{ pkgs, ... }:
{
  imports = [
    ../modules/ai.nix
    ../modules/apps.nix
    ../modules/spicetify.nix
    ../modules/gnome.nix
  ];

  home.packages = with pkgs; [
    yt-dlp
  ];
}
