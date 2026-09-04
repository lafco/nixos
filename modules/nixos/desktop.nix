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

  # O XFCE ativa services.graphical-desktop, que liga o set padrão de
  # fontes (DejaVu, Liberation, unifont e Noto CJK/Emoji). Desligamos para
  # controlar 100% da lista abaixo (Noto fora).
  fonts.enableDefaultPackages = false;

  fonts.packages = with pkgs; [
    ubuntu-sans # fonte padrão do sistema (sans-serif)
    nerd-fonts.symbols-only # ícones do prompt starship
    jetbrains-mono # fonte pedida pelo wezterm (wezterm.lua: 'Jetbrains Mono')
  ];

  # Ubuntu Sans como sans-serif padrão do fontconfig: o alias "Sans"
  # (usado pelo XFCE e apps GTK por padrão) resolve para ela.
  # ⚠️ Noto foi removida — sem fonte de emoji colorido agora; se quiser
  # emojis de volta, adicione p.ex. joypixels ou openmoji aqui.
  fonts.fontconfig.defaultFonts.sansSerif = [ "Ubuntu Sans" ];

  # Aplicativos gráficos padrão (adicione os seus aqui).
  environment.systemPackages = with pkgs; [
    firefox
    thunar # file manager GUI (já vem com o XFCE; explícito por clareza)
    xfce4-screenshooter # usado pelo keybind Print (home/modules/xfce)
    wezterm # terminal padrão (home/modules/xfce.nix: helpers.rc do exo);
    # no systemPackages para o exo-open achá-lo no PATH da sessão gráfica
    # (o home.packages do usuário nem sempre está no PATH do SDDM/XFCE)
    yaru-theme # cursor "Yaru" do Ubuntu (setado em home/modules/xfce/xsettings.xml)

    # Plugins do painel XFCE (adicione pelo GUI: Painel → Add New Items).
    # O Status Notifier/tray é embutido no xfce4-panel 4.20 (sem pacote).
    xfce4-whiskermenu-plugin # menu de apps com busca/favoritos
    xfce4-docklike-plugin # taskbar estilo dock (pin de apps)
    xfce4-clipman-plugin # histórico de clipboard
    xfce4-genmon-plugin # monitor genérico (scripts custom)
    # alacritty
    # vlc
  ];
}
