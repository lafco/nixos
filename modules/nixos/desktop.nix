# Ambiente gráfico da máquina de uso diário: XFCE + SDDM + PipeWire +
# Bluetooth + fontes.
{ pkgs, ... }:
{
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    # Se um dia usar GPU NVIDIA, descomente:
    # videoDrivers = [ "nvidia" ];
  };

  # SDDM como display manager (o LightDM foi removido do nixpkgs em 2025).
  services.displayManager.sddm.enable = true;
  services.displayManager.defaultSession = "xfce";

  networking.networkmanager.enable = true;

  # Áudio via PipeWire.
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
  };

  # Bluetooth (fones, controle de jogo etc.). O blueman dá o applet no
  # systray do painel (o painel em si é configurado em home/modules/xfce).
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Touchpad/trackpad.
  services.libinput.enable = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    nerd-fonts.symbols-only # ícones do prompt starship
  ];

  # Aplicativos gráficos padrão (adicione os seus aqui).
  environment.systemPackages = with pkgs; [
    firefox
    thunar # file manager GUI (já vem com o XFCE; explícito por clareza)
    xfce4-screenshooter # usado pelo keybind Print (home/modules/xfce)
    # alacritty
    # vlc
  ];
}
