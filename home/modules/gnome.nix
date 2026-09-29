# GNOME (só na daily): keybinds, aparência, áreas de trabalho, pinning de apps
# e extensões (tray e dock), tudo via dconf.
#
# O home-manager escreve o dconf em ~/.config/dconf/user. Como isso é o banco
# do USUÁRIO, os valores abaixo vencem os defaults do sistema
# (nixos-gsettings-overrides).
#
# ⚠️ A sessão do GNOME 50 é Wayland-only (a sessão Xorg saiu no 49). Binds que
# dependem de X11 (xkill) só afetam clientes XWayland.
#
# Keybinds:
#   Super+Return      -> terminal (wezterm + herdr)   [favorito 1 do dash]
#   Super+e           -> gerenciador de arquivos (nautilus)  [custom]
#   Super+f           -> firefox                      [favorito 3 do dash]
#   Super+m           -> spotify (área 4)             [favorito 4 do dash]
#   Super+k           -> xkill                               [custom]
#   Super+q           -> fechar janela (soma ao Alt+F4 do GNOME)
#   Super+t           -> fullscreen
#   Super+Up/Down     -> maximizar/restaurar (já é default do GNOME)
#   Super+Left/Right  -> ladrilhar (já é default do mutter)
#   Super+1..4        -> áreas de trabalho 1..4
#   Shift+Super+1..4  -> mover janela para a área 1..4
#   Super+Page_Up/Down         -> trocar de área (já é default)
#   Alt+Super+Page_Up/Down     -> mover janela de área
#   Super+l           -> bloquear (já é default do GNOME)
#   Super+a           -> application finder (xfce4-appfinder, instalado nas
#                        home.packages abaixo); o default do GNOME era a
#                        grade de apps do overview, desligada abaixo
#   Print/Alt+Print   -> screenshot (já é default do GNOME)
#   Delay/Rate do teclado -> 200ms / 45 repetições por segundo
#   XF86Audio*        -> volume nativo do GNOME
#   Super+equal/minus -> volume via wpctl (sem o OSD do GNOME)
#
# Além dos keybinds, este módulo fixa 4 áreas de trabalho estáticas e usa a
# extensão auto-move-windows para pinar apps na sua área (wezterm -> 1,
# firefox -> 2, steam/ankama/jogos -> 3, spotify -> 4). Exige
# dynamic-workspaces = false: com áreas dinâmicas os números mudam quando uma
# área fica vazia.
#
# ⚠️ A lista usa o id do .desktop COM o sufixo `.desktop`. A extensão chama
# Shell.AppSystem.lookup_app(id), que compara com g_app_info_get_id() (o id
# XDG, que inclui o sufixo); sem ele o lookup devolve NULL e a regra é
# descartada em silêncio — era o que acontecia antes.
#
# O "focar se aberto, senão abrir" do terminal/firefox não é um comando: é o
# switch-to-application-N do próprio Shell, que chama app.activate() — foca a
# janela mais recente do app (trocando para a área dela) ou lança uma nova.
# Como o N indexa os FAVORITOS do dash, favorite-apps é declarado aqui, e a
# ordem do dash passa a vir da config (reordenar pelo GUI é revertido).
#
# Ctrl+Return NÃO é bound de propósito: tecla de binding do Shell é capturada
# globalmente, então o app focado (wezterm, Firefox) nunca a receberia.
#
# Jogos da Steam também são pinados (ver steamGames no let): como a Steam não
# cria .desktop para jogos da loja, o módulo gera um por jogo para o GNOME
# conseguir associar a janela ao app.
#
# A dock (dash-to-dock) fica embaixo com auto-hide. Duas chaves default dela
# são desligadas porque colidem com o resto: `hot-keys` (Super+1..9 -> app) e
# `shortcut` (Super+q -> mostra/esconde a dock).
#
# O Alt+Tab (app-switcher) é limitado à área atual — o default lista apps de
# todas as áreas. O Super+Tab (window-switcher) já vem com esse limite.
{ lib, pkgs, ... }:
let
  # Keybinds de comando. Os binários vêm dos systemPackages do host daily
  # (modules/nixos/desktop.nix) — o GNOME herda o PATH da sessão gráfica.
  customs = [
    {
      name = "Gerenciador de arquivos";
      command = "nautilus";
      binding = "<Super>e";
    }
    {
      name = "Application finder";
      command = "xfce4-appfinder";
      binding = "<Super>a";
    }
    {
      name = "Xkill";
      command = "xkill";
      binding = "<Super>k";
    }
    {
      name = "Volume +";
      command = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+";
      binding = "<Super>equal";
    }
    {
      name = "Volume -";
      command = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-";
      binding = "<Super>minus";
    }
  ];

  customId = i: "custom${toString i}";

  # Cada custom binding é um schema relocável em
  # /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/customN/.
  customSettings = lib.listToAttrs (
    lib.imap0 (i: c: {
      name = "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/${customId i}";
      value = { inherit (c) name command binding; };
    }) customs
  );

  # Lista que amarra os customN ao media-keys (mesmos paths, na mesma ordem).
  customPaths = map (
    i: "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/${customId i}/"
  ) (lib.range 0 (lib.length customs - 1));

  # Array vazio tipado: `[]` cru perde o tipo e o dconf recusa.
  noKeys = lib.gvariant.mkEmptyArray lib.gvariant.type.string;

  # Jogos da Steam fixados numa área de trabalho.
  #
  # O auto-move-windows casa por id de .desktop (Shell.AppSystem.lookup_app),
  # e a Steam NÃO cria .desktop para jogos da loja — então geramos um aqui.
  # O WM_CLASS da janela do jogo é "steam_app_<appid>" (confirmado com xprop),
  # e é por isso que o arquivo precisa se chamar exatamente assim: o GNOME
  # associa a janela ao app por StartupWMClass / basename do .desktop.
  #
  # Para adicionar um jogo: pegue o appid (appmanifest_<appid>.acf em
  # ~/.local/share/Steam/steamapps/) e adicione uma entrada na lista.
  steamGames = [
    {
      appid = 1285190;
      name = "Borderlands 4";
      workspace = 3;
    }
  ];

  gameId = g: "steam_app_${toString g.appid}";

  gameDesktopEntries = lib.listToAttrs (
    map (g: {
      name = "applications/${gameId g}.desktop";
      value.text = ''
        [Desktop Entry]
        Type=Application
        Name=${g.name}
        Comment=Jogo da Steam (appid ${toString g.appid})
        Exec=steam steam://rungameid/${toString g.appid}
        Icon=steam
        Terminal=false
        Categories=Game;
        StartupWMClass=${gameId g}
      '';
    }) steamGames
  );

  gameAutoMove = map (g: "${gameId g}.desktop:${toString g.workspace}") steamGames;

  # .desktop do wezterm com o herdr.
  #
  # O entry do pacote é `Exec=wezterm start --cwd .` e o wezterm.lua dos
  # dotfiles usa `default_prog = bash -l`: lançar pelo favorito abriria um bash
  # em vez do herdr que o keybind usava. O arquivo é sobrescrito em
  # ~/.local/share/applications (que tem prioridade sobre o do sistema), com o
  # MESMO id e StartupWMClass — assim o auto-move-windows e o WindowTracker
  # continuam associando a janela a este app.
  weztermDesktopName = "applications/org.wezfurlong.wezterm.desktop";
  weztermDesktop = ''
    [Desktop Entry]
    Name=WezTerm
    Comment=Wez's Terminal Emulator
    Keywords=shell;prompt;command;commandline;cmd;
    Icon=org.wezfurlong.wezterm
    StartupWMClass=org.wezfurlong.wezterm
    TryExec=wezterm
    Exec=wezterm start --cwd . -- herdr
    Type=Application
    Categories=System;TerminalEmulator;Utility;
    Terminal=false
  '';
in
{
  # O appfinder do Super+a vinha do desktopManager.xfce (removido do repo) —
  # agora é instalado direto. O Papirus é o icon-theme do GNOME (abaixo).
  home.packages = [
    pkgs.xfce4-appfinder
    pkgs.papirus-icon-theme
  ];

  # .desktop dos jogos da Steam (ver o comentário em steamGames acima) e do
  # wezterm com herdr (ver weztermDesktop).
  xdg.dataFile = gameDesktopEntries // {
    ${weztermDesktopName}.text = weztermDesktop;
  };

  dconf.settings = customSettings // {
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = customPaths;
    };

    "org/gnome/desktop/wm/keybindings" = {
      close = [
        "<Super>q"
        "<Alt>F4"
      ];
      toggle-fullscreen = [ "<Super>t" ];

      # O default do GNOME só tem Super+Home na área 1.
      switch-to-workspace-1 = [ "<Super>1" ];
      switch-to-workspace-2 = [ "<Super>2" ];
      switch-to-workspace-3 = [ "<Super>3" ];
      switch-to-workspace-4 = [ "<Super>4" ];
      move-to-workspace-1 = [ "<Super><Shift>1" ];
      move-to-workspace-2 = [ "<Super><Shift>2" ];
      move-to-workspace-3 = [ "<Super><Shift>3" ];
      move-to-workspace-4 = [ "<Super><Shift>4" ];

      # O default já cobre Super+Shift+Page_Up/Down; aqui somamos o
      # Alt+Super+Page_Up/Down, herdado da época do xfwm4.
      move-to-workspace-left = [
        "<Super><Shift>Page_Up"
        "<Super><Alt>Page_Up"
      ];
      move-to-workspace-right = [
        "<Super><Shift>Page_Down"
        "<Super><Alt>Page_Down"
      ];
    };

    # Áreas de trabalho estáticas: a numeração precisa ser estável para o
    # auto-move-windows (e para os binds Super+1..4) fazerem sentido. São 4.
    "org/gnome/mutter" = {
      dynamic-workspaces = false;
    };
    "org/gnome/desktop/wm/preferences" = {
      num-workspaces = 4;
    };

    "org/gnome/shell/keybindings" = {
      # Super+1..4 fica para as áreas de trabalho — mas o
      # switch-to-application-N segue sendo o "focar se aberto, senão abrir" do
      # Shell, só com outras teclas: 1 = favorito 1 (wezterm), 3 = favorito 3
      # (firefox), 4 = favorito 4 (spotify); ver favorite-apps abaixo. O 2 fica
      # vazio.
      switch-to-application-1 = [ "<Super>Return" ];
      switch-to-application-2 = noKeys;
      switch-to-application-3 = [ "<Super>f" ];
      switch-to-application-4 = [ "<Super>m" ];

      # Libera Super+a: acima ele volta a ser o appfinder.
      toggle-application-view = noKeys;
    };

    # Alt+Tab só passa pelos apps que têm janela na área atual; sem isso ele
    # lista apps de todas as áreas, mesmo com só 3 áreas fixas.
    "org/gnome/shell/app-switcher" = {
      current-workspace-only = true;
    };

    # Extensões: o pacote está nos systemPackages (modules/nixos/desktop.nix);
    # aqui só habilitamos pelos UUIDs.
    #   appindicator      -> tray (o GNOME Shell não mostra ícones de bandeja)
    #   auto-move-windows -> fixa apps em áreas (ver bloco abaixo)
    #   dash-to-dock      -> dock embaixo com auto-hide (ver bloco abaixo)
    "org/gnome/shell" = {
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
        "dash-to-dock@micxgx.gmail.com"
      ];

      # Ordem do dash — é ela que dá o índice do switch-to-application-N (1 =
      # wezterm, 3 = firefox, 4 = spotify), por isso a lista é declarativa. O
      # obsidian fica no meio porque já estava no dash.
      favorite-apps = [
        "org.wezfurlong.wezterm.desktop"
        "obsidian.desktop"
        "firefox.desktop"
        "spotify.desktop"
      ];
    };

    # Dock estilo macOS, mantendo a top bar. Os defaults já são bottom +
    # auto-hide; o que importa aqui são as duas colisões desligadas.
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "BOTTOM";
      autohide = true;
      dock-fixed = false;
      intellihide = true;
      extend-height = false; # dock flutuante, não esticada na tela toda

      # Default true: Super+1..9 abriria/trocaria o app na dock, brigando com
      # as áreas de trabalho fixas.
      hot-keys = false;
      # Default ['<Super>q']: mostra/esconde a dock, brigando com fechar janela.
      shortcut = noKeys;
    };

    # app -> área de trabalho. O id é o nome do .desktop COM o sufixo (ver o
    # aviso no topo do arquivo); para pegar o de uma janela aberta:
    #   DISPLAY=:0 XAUTHORITY=~/.mutter-Xwaylandauth.* xprop -id <id> WM_CLASS
    # Jogos da Steam entram via gameAutoMove (ver steamGames no let).
    "org/gnome/shell/extensions/auto-move-windows" = {
      application-list = [
        "org.wezfurlong.wezterm.desktop:1"
        "firefox.desktop:2"
        "steam.desktop:3"
        "ankama-launcher.desktop:3"
        "spotify.desktop:4"
      ]
      ++ gameAutoMove;
    };

    # Aparência do GNOME. cursor-theme e icon-theme eram espelhados do
    # ./xfce/xsettings.xml na época em que as duas sessões existiam.
    "org/gnome/desktop/interface" = {
      icon-theme = "Papirus-Dark";
      cursor-theme = "Yaru";
      gtk-theme = "Adwaita-dark";
      color-scheme = "prefer-dark";
      accent-color = "orange";
      font-name = "Ubuntu Sans 10";
      monospace-font-name = "JetBrains Mono 10";
    };

    # Teclado: 200ms de delay e 45 repetições por segundo (os mesmos valores
    # que o XFCE usava). O GNOME guarda o intervalo ENTRE repetições, em ms:
    # 1000/45 ≈ 22ms.
    "org/gnome/desktop/peripherals/keyboard" = {
      delay = lib.gvariant.mkUint32 200;
      repeat-interval = lib.gvariant.mkUint32 22;
    };

    # Não suspender nem apagar a tela: a máquina precisa ficar alcançável
    # (herdr/Tailscale). Mesmo motivo do "inactivity = 0" que existia no XFCE.
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
    };
    "org/gnome/desktop/session" = {
      idle-delay = lib.gvariant.mkUint32 0;
    };
  };
}
