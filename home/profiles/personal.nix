# Perfil PESSOAL — usado na máquina de uso diário (NixOS "daily").
# Adiciona os módulos "pesados"/de desktop (apps gráficos + agentes de IA +
# keybinds/aparência do GNOME e do XFCE) que não fazem sentido nas outras
# máquinas. Os dois módulos de desktop coexistem: o GDM escolhe a sessão.
{ pkgs, ... }:
{
  imports = [
    ../modules/ai.nix
    ../modules/apps.nix
    ../modules/spicetify.nix
    ../modules/gnome.nix
    ../modules/xfce.nix
  ];

  home.packages = with pkgs; [
    yt-dlp
  ];
}
