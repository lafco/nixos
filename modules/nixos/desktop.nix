# Ambiente gráfico da máquina de uso diário: XFCE + LightDM + PipeWire + fontes.
{ pkgs, ... }:
{
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    # Se um dia usar GPU NVIDIA, descomente:
    # videoDrivers = [ "nvidia" ];
  };

  services.displayManager.lightdm.enable = true;
  services.displayManager.defaultSession = "xfce";

  networking.networkmanager.enable = true;

  # Áudio via PipeWire.
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
  };

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
    # alacritty
    # vlc
  ];
}
