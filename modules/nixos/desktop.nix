# Ambiente gráfico da máquina de uso diário: GNOME + GDM + PipeWire +
# Bluetooth + fontes.
#
# Só o GNOME é instalado (Wayland-only na versão 50), então o GDM lista uma
# única sessão. A config do desktop mora em home/modules/gnome.nix.
{ pkgs, ... }:
{
  # XWayland vem daqui: Steam, jogos da Steam e o Proton Pass rodam como
  # clientes X11 sob a sessão Wayland (aparecem na lista de janelas do
  # XWayland). Não é mais por causa de um desktop X11.
  services.xserver = {
    enable = true;
    # Se um dia usar GPU NVIDIA, descomente:
    # videoDrivers = [ "nvidia" ];
  };

  # GNOME 50 é Wayland-only (a sessão Xorg saiu no 49). O módulo do nixpkgs
  # recomenda o GDM: com outro display manager a sessão Wayland não funciona
  # direito e o lock de tela (Super+L) não trava.
  services.desktopManager.gnome.enable = true;

  # GDM substitui o SDDM (só um display manager por host; o LightDM foi
  # removido do nixpkgs em 2025). Ele lista só a sessão GNOME.
  services.displayManager.gdm.enable = true;
  services.displayManager.defaultSession = "gnome";

  networking.networkmanager.enable = true;

  # Áudio via PipeWire.
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
  };

  # Bluetooth (fones, controle de jogo etc.). O blueman é a GUI de pareamento;
  # no GNOME ele só aparece com a extensão appindicator (habilitada em
  # home/modules/gnome.nix) — o GNOME Shell não tem systray.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Touchpad/trackpad.
  services.libinput.enable = true;

  # services.graphical-desktop (ligado por services.xserver.enable) ativa o
  # set padrão de fontes (DejaVu, Liberation, unifont e Noto CJK/Emoji).
  # Desligamos para controlar 100% da lista abaixo (Noto fora).
  fonts.enableDefaultPackages = false;

  fonts.packages = with pkgs; [
    ubuntu-sans # fonte padrão do sistema (sans-serif)
    nerd-fonts.symbols-only # ícones do prompt starship
    jetbrains-mono # fonte pedida pelo wezterm (wezterm.lua: 'Jetbrains Mono')
  ];

  # Ubuntu Sans como sans-serif padrão do fontconfig: o alias "Sans"
  # (usado por apps GTK e pelo GNOME por padrão) resolve para ela.
  # ⚠️ Noto foi removida — sem fonte de emoji colorido agora; se quiser
  # emojis de volta, adicione p.ex. joypixels ou openmoji aqui.
  fonts.fontconfig.defaultFonts.sansSerif = [ "Ubuntu Sans" ];

  # Aplicativos gráficos padrão (adicione os seus aqui).
  environment.systemPackages = with pkgs; [
    firefox
    # O gerenciador de arquivos do GNOME é o nautilus, que vem do módulo
    # desktopManager.gnome — é ele que o Super+e abre (home/modules/gnome.nix).
    wezterm # terminal padrão; no systemPackages para estar no PATH da sessão
    # gráfica (o home.packages do usuário nem sempre está no PATH do GDM)
    yaru-theme # cursor "Yaru" do Ubuntu (setado em home/modules/gnome.nix)

    # Tray do GNOME: o GNOME Shell não mostra ícones de bandeja (blueman etc.)
    # sem esta extensão. Ela é habilitada via dconf em home/modules/gnome.nix.
    gnomeExtensions.appindicator

    # Fixa apps em áreas de trabalho (wezterm -> 1, firefox -> 2, steam -> 3).
    # Configurada em home/modules/gnome.nix; exige áreas estáticas.
    gnomeExtensions.auto-move-windows

    # Dock estilo macOS (auto-hide, embaixo), mantendo a top bar. Configurada
    # em home/modules/gnome.nix (com hot-keys = false, senão Super+1..9 briga
    # com os binds de área de trabalho).
    gnomeExtensions.dash-to-dock
    # alacritty
    # vlc
  ];

  # O GNOME Web (Epiphany) vem da lista core-apps do módulo
  # desktopManager.gnome e é o ÚNICO outro browser do sistema. Removido: só o
  # firefox é usado.
  environment.gnome.excludePackages = with pkgs; [
    epiphany
  ];

  # Browser padrão. Sem um mimeapps.list, o glib (gio, que é o que os apps
  # chamam para abrir link) resolve text/html e x-scheme-handler/* para o
  # Epiphany — era por isso que clicar num link abria o GNOME Web, mesmo com o
  # firefox instalado. Aqui o default fica explícito; o arquivo gerado é
  # /etc/xdg/mimeapps.list.
  xdg.mime.defaultApplications = {
    "text/html" = "firefox.desktop";
    "application/xhtml+xml" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
  };
}
