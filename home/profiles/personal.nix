# Perfil PESSOAL — usado na máquina de uso diário (NixOS "daily").
# Adiciona os módulos "pesados"/de desktop do repo de dotfiles
# (apps gráficos + agentes de IA) que não fazem sentido nas outras máquinas.
{ inputs, pkgs, ... }:
{
  imports = [
    (inputs.dotfiles + "/nixos/modules/home/ai.nix")
    (inputs.dotfiles + "/nixos/modules/home/apps.nix")
  ];

  home.packages = with pkgs; [
    yt-dlp
  ];
}
