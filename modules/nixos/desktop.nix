# Ambiente gráfico da máquina de uso diário: GNOME + GDM + PipeWire +
# Bluetooth + fontes.
#
# Só o GNOME é instalado (Wayland-only na versão 50), então o GDM lista uma
# única sessão. A config do desktop mora em home/modules/gnome.nix.
{ pkgs, ... }:
{
  # XWayland vem daqui: Steam e jogos da Steam rodam como clientes X11 sob a
  # sessão Wayland (aparecem na lista de janelas do XWayland). Não é mais por
  # causa de um desktop X11.
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
  # Desligamos para controlar 100% da lista abaixo.
  fonts.enableDefaultPackages = false;

  fonts.packages = with pkgs; [
    ubuntu-sans # fonte padrão do sistema (sans-serif)
    nerd-fonts.symbols-only # ícones do prompt starship
    jetbrains-mono # fonte dos terminais (herdr-app, ghostty)

    # Sem estas, CJK (部署指南) cai no bitmap 'Fixed' do font-misc-misc
    # (12x13ja.pcf.gz, fonte X11 de bitmap que só cobre JIS X 0208 — o resto
    # vira tofu) e não existe emoji nenhum no sistema. O Firefox/GTK usam o
    # fontconfig, então basta instalar; o ghostty declara a lista explícita no
    # config dele (~/dotfiles/ghostty/.config/ghostty/config).
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  # Ubuntu Sans como sans-serif padrão do fontconfig: o alias "Sans"
  # (usado por apps GTK e pelo GNOME por padrão) resolve para ela. O emoji
  # precisa de alias próprio, senão o fontconfig não acha quem desenha U+1F600.
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Ubuntu Sans" ];
    emoji = [ "Noto Color Emoji" ];
  };

  # Aplicativos gráficos padrão (adicione os seus aqui).
  environment.systemPackages = with pkgs; [
    firefox
    # O gerenciador de arquivos do GNOME é o nautilus, que vem do módulo
    # desktopManager.gnome — é ele que o Super+e abre (home/modules/gnome.nix).
    #
    # O terminal padrão é o herdr (app desktop), instalado por home.packages em
    # home/modules/ai.nix — não precisa estar aqui: o que o GNOME usa é o
    # .desktop do ~/.nix-profile, e é a partir dele que o herdr-app é lançado.
    yaru-theme # cursor "Yaru" do Ubuntu (setado em home/modules/gnome.nix)

    # Tray do GNOME: o GNOME Shell não mostra ícones de bandeja (blueman etc.)
    # sem esta extensão. Ela é habilitada via dconf em home/modules/gnome.nix.
    gnomeExtensions.appindicator

    # Fixa apps em áreas de trabalho (herdr -> 1, firefox -> 2, steam -> 3).
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
  #
  # O gnome-text-editor também sai: o editor padrão é o Zed (ver
  # xdg.mime.defaultApplications abaixo), e sem o duplo clique abrindo o
  # TextEditor não há motivo para o app ficar no sistema.
  #
  # O seahorse ("Senhas e chaves" / Password and Keys) também sai: as senhas
  # ficam no 1Password. O daemon gnome-keyring continua ligado (é ele que o
  # GNOME/GDM/NetworkManager usam por baixo dos panos) — só a GUI é removida.
  environment.gnome.excludePackages = with pkgs; [
    epiphany
    gnome-text-editor
    seahorse
  ];

  # 1Password: GUI + CLI (`op`) vêm dos módulos do nixpkgs, que instalam os
  # wrappers setgid (`1Password-BrowserSupport` em /run/wrappers/bin e `op`) e
  # a integração polkit. `polkitPolicyOwners` é o que libera o desbloqueio por
  # senha/fingerprint do sistema na GUI; sem ele o polkit nega.
  #
  # A ponte extensão do Firefox ↔ app é o native messaging host: o JSON que
  # autoriza o 1Password-BrowserSupport (a wrapper setgid instalada acima pelo
  # módulo) a atender a extensão. Ele é declarado em home/modules/apps.nix
  # (~/.mozilla/native-messaging-hosts/com.1password.1password.json); o próprio
  # app também grava esse arquivo quando roda, e os dois conteúdos batem.
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "lafco" ];
  };

  # Browser padrão. Sem um mimeapps.list, o glib (gio, que é o que os apps
  # chamam para abrir link) resolve text/html e x-scheme-handler/* para o
  # Epiphany — era por isso que clicar num link abria o GNOME Web, mesmo com o
  # firefox instalado. Aqui o default fica explícito; o arquivo gerado é
  # /etc/xdg/mimeapps.list.
  #
  # mailto vai para o app da Fastmail (pacote em home/modules/apps.nix); o Exec
  # do .desktop é `fastmail %U`, então o `mailto:` chega inteiro. Não há
  # `webcal:` aqui porque o .desktop do app só declara
  # `x-scheme-handler/mailto` e `x-scheme-handler/fastmail`.
  #
  # text/plain e application/x-zerosize são exatamente os dois tipos que o
  # gnome-text-editor reivindicava (o segundo é o arquivo vazio, "novo
  # documento"): os dois vão para o Zed, que é o editor padrão. O id é
  # dev.zed.Zed.desktop (o binário do nixpkgs é `zeditor`; pkgs.zed é outro
  # produto). O Zed mora no home.packages (home/modules/apps.nix) — o gio lê o
  # .desktop do perfil do usuário, então funciona mesmo não estando no
  # systemPackages. text/markdown já aponta para o Zed em
  # ~/.config/mimeapps.list, que o próprio app escreve e que tem prioridade.
  xdg.mime.defaultApplications = {
    "text/html" = "firefox.desktop";
    "application/xhtml+xml" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "x-scheme-handler/mailto" = "fastmail.desktop";

    "text/plain" = "dev.zed.Zed.desktop";
    "application/x-zerosize" = "dev.zed.Zed.desktop";
  };
}
