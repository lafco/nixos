# Jogos (só na daily): Steam + GameMode + MangoHud + Gamescope.
# GPU AMD RX 7600 — mesa/radv funcionam out-of-the-box no NixOS.
#
# O Ankama Launcher (Dofus/Waven/Wakfu) é package do HOME, instalado em
# home/modules/apps.nix (o launcher é unfree e roda AppImage + wine).
{ pkgs, ... }:
{
  # Steam (o módulo também habilita o driver 32-bit por padrão).
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  # GameMode: otimiza o sistema durante o jogo.
  programs.gamemode.enable = true;

  # Driver gráfico 32-bit — necessário para jogos/proton antigos.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Áudio 32-bit (jogos antigos no Steam).
  services.pipewire.alsa.support32Bit = true;

  environment.systemPackages = with pkgs; [
    mangohud # overlay de FPS/temperaturas
    gamescope # microcompositor p/ jogos (upscaling, HDR, etc.)
    radeontop # monitor de uso da GPU no terminal
    vulkan-tools # vulkaninfo para diagnosticar Vulkan
  ];
}
