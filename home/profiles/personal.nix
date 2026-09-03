# Perfil PESSOAL — usado na máquina de uso diário (NixOS "daily").
# Adiciona os módulos "pesados"/de desktop (apps gráficos + agentes de IA +
# painel/keybinds do XFCE) que não fazem sentido nas outras máquinas.
{ pkgs, ... }:
{
  imports = [
    ../modules/ai.nix
    ../modules/apps.nix
    ../modules/xfce.nix
  ];

  home.packages = with pkgs; [
    yt-dlp
  ];
}
