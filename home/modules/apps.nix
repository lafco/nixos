# Apps de desktop: Firefox (declarativo) + 1Password + Fastmail + IDEs (Zed, Och)
# Firefox: extensões e preferências versionadas; login/sync continua manual (1x).
# 1Password: GUI e CLI vêm dos módulos do NixOS (programs._1password e
# _1password-gui, em modules/nixos/desktop.nix) — aqui ficam a extensão do
# Firefox e a entrada de autostart (xdg.autostart), as partes que o
# home-manager instala declarativamente.
#
# O Zed é só o PACOTE: settings/keymap vêm do repo de
# dotfiles via symlink (home/modules/dotfiles.nix), não do módulo
# `programs.zed-editor` do home-manager — ele escreveria o settings.json e
# brigaria com o symlink.
{ pkgs, ... }:
let
  # Extensões do Firefox — todas vêm do overlay `firefox-addons`
  # (lib/overlays.nix). Versão + hash ficam no flake.lock: atualize com
  # `nix flake update firefox-addons`.
  #
  # NÃO usar `pkgs.fetchFirefoxAddon` para isto, por dois motivos:
  #  1. ele deixa o .xpi na RAIZ do pacote, mas o módulo Firefox do
  #     home-manager copia `<pkg>/share/mozilla/extensions/{ec8030f7-…}` — com
  #     o fetchFirefoxAddon isso não existe e a extensão simplesmente não era
  #     instalada (ficava um symlink pendurado em <perfil>/extensions);
  #  2. ele reescreve o `gecko.id` do manifesto para `nixos@<nome>`, e as
  #     integrações dependem do ID real do AMO (native messaging do 1Password
  #     ↔ app desktop e do Pywalfox ↔ CLI, e o próprio Firefox Sync).
  # O nome leva sufixo `-extension` de propósito: um binding `onepassword`
  # aqui sombrearia um pacote de mesmo nome do `with pkgs` em home.packages.
  ublock-origin-extension = pkgs.firefox-addons.ublock-origin;
  # No nixpkgs a extensão usa o slug do AMO ("1password-x-password-manager"),
  # que é o mesmo produto que a 1Password chama de "1Password for Firefox".
  # O addonId ({d634138d-c276-4fc8-924b-40a0ea21d284}) é o de sempre — é ele
  # que o native messaging host do app procura.
  onepassword-extension = pkgs.firefox-addons."1password-x-password-manager";
  pywalfox-extension = pkgs.firefox-addons.pywalfox; # tema do Firefox seguindo a paleta do Noctalia

  # ID canônico da extensão (é ele que o Firefox usa em
  # browser-extension-data/<id>/). O pacote do overlay expõe `addonId`; o
  # fetchFirefoxAddon do nixpkgs expõe `extid` — aceitamos os dois.
  ublock-origin-id = ublock-origin-extension.extid or ublock-origin-extension.addonId;

  # Native messaging do 1Password: é este JSON que autoriza a extensão do
  # Firefox a falar com o app (destravar o cofre junto com o app em vez de
  # pedir a senha mestra de novo). O formato e os IDs saem do próprio app; o
  # `path` aponta para o wrapper setgid `1Password-BrowserSupport` que o módulo
  # programs._1password-gui instala em /run/wrappers/bin (modules/nixos/desktop.nix)
  # — caminho estável, ao contrário do /nix/store do pacote, que muda a cada
  # bump e quebraria o manifest.
  #
  # O app também grava esse arquivo sozinho em ~/.mozilla/native-messaging-hosts
  # quando roda, mas declarar aqui deixa a integração de pé desde o primeiro
  # boot — e, se o app reescrever, o conteúdo é equivalente.
  onepassword-native-host = pkgs.writeTextFile {
    name = "com.1password.1password.json";
    text = builtins.toJSON {
      name = "com.1password.1password";
      description = "1Password BrowserSupport";
      path = "/run/wrappers/bin/1Password-BrowserSupport";
      type = "stdio";
      # {d634138d-…} é a extensão atual; as outras duas são builds antigos do
      # 1Password X que o app também lista.
      allowed_extensions = [
        "{0a75d802-9aed-41e7-8daa-24c067386e82}"
        "{25fc87fa-4d31-4fee-b5c1-c32a7844c063}"
        "{d634138d-c276-4fc8-924b-40a0ea21d284}"
      ];
    };
  };

  # "My filters" do uBlock Origin — bloqueio de YouTube Shorts.
  # O uBO guarda esse conteúdo em storage.local sob a chave `user-filters`
  # (assets.js: µb.userFiltersPath), que é a chave usada no
  # `extensions.settings` mais abaixo. Não é `userFilters`.
  shortsFilters = ''
    ! Bloqueio de YouTube Shorts — declarativo em home/modules/apps.nix
    ! (cobre youtube.com e m.youtube.com)
    ||youtube.com/shorts/$document
    youtube.com##ytd-rich-shelf-renderer[is-shorts]
    youtube.com##ytd-reel-shelf-renderer
    youtube.com##ytd-guide-entry-renderer:has(a[href^="/shorts/"])
    youtube.com##ytd-mini-guide-entry-renderer:has(a[href^="/shorts/"])
    youtube.com##ytd-rich-item-renderer:has(a[href^="/shorts/"])
    youtube.com##ytd-video-renderer:has(a[href^="/shorts/"])
    youtube.com##ytd-compact-video-renderer:has(a[href^="/shorts/"])
    youtube.com##yt-tab-shape[tab-title="Shorts"]
    m.youtube.com##ytm-pivot-bar-item-renderer:has(a[href^="/shorts/"])
    m.youtube.com##ytm-reel-shelf-renderer
    m.youtube.com##ytm-shorts-lockup-view-model
  '';

  # Camada redundante: esconde a UI de Shorts via userContent.css, útil
  # enquanto o uBO não aplicou os filtros (primeira execução / listas
  # desatualizadas). Exige o pref legacyUserProfileCustomizations abaixo.
  shortsCss = ''
    /* Bloqueio de YouTube Shorts — injetado por home/modules/apps.nix.
       `domain("youtube.com")` cobre youtube.com e subdomínios
       (www. e m.). Requer
       toolkit.legacyUserProfileCustomizations.stylesheets = true. */
    @-moz-document domain("youtube.com") {
      ytd-rich-shelf-renderer[is-shorts],
      ytd-reel-shelf-renderer,
      ytd-guide-entry-renderer:has(a[href^="/shorts/"]),
      ytd-mini-guide-entry-renderer:has(a[href^="/shorts/"]),
      ytd-rich-item-renderer:has(a[href^="/shorts/"]),
      ytd-video-renderer:has(a[href^="/shorts/"]),
      ytd-compact-video-renderer:has(a[href^="/shorts/"]),
      yt-tab-shape[tab-title="Shorts"],
      ytm-pivot-bar-item-renderer:has(a[href^="/shorts/"]),
      ytm-reel-shelf-renderer,
      ytm-shorts-lockup-view-model {
        display: none !important;
      }
    }
  '';
in
{
  home.packages = with pkgs; [
    # App oficial da Fastmail (Electron, unfree): é ele que abre os links
    # `mailto:` — o default fica em modules/nixos/desktop.nix.
    fastmail-desktop
    # Zed: o nixpkgs do estável (26.05) pinaria 1.3.6, mas o keymap do repo de
    # dotfiles foi escrito contra o Zed 1.16 (ver o comentário do outline::Toggle
    # em ~/dotfiles/zed/.config/zed/keymap.json). O unstable traz 1.17.2.
    # `pkgs.unstable` vem do overlay em lib/overlays.nix.
    pkgs.unstable.zed-editor # binário: `zeditor`; config em ~/.config/zed -> ~/dotfiles/zed
    # NÃO usar pkgs.zed: esse é o CLI do data lake da Brim Data
    # (zed.brimdata.io), não o editor do zed.dev — e é por isso que o binário
    # do editor se chama `zeditor` no nixpkgs.
    # Och: fork/rebrand do OpenChamber, IDE agêntica em cima do OpenCode
    # (Electron, AppImage do release do fork) — ver pkgs/och.nix. Em teste: o
    # app embute o próprio OpenCode CLI, então não usa o pkgs/opencode-v2 daqui.
    och
    # O updater interno é desativado pelo overlay: o AppImage fica imutável no
    # /nix/store e novas versões são aplicadas pelo flake/Nix.
    ankama-launcher # jogos Ankama (Dofus, Waven, Wakfu…) — AppImage + wine
    # Discord oficial (Electron). SEM Vencord e SEM OpenAsar (2026-11-16):
    #
    # - OpenAsar (pinado no nixpkgs, 0-unstable-2026-07-24) quebra com o
    #   Electron do Discord 1.0.138 — o `ipcRenderer.send('cs', c)` manda um
    #   objeto não clonável, o setup aborta e a janela fica preta.
    # - Vencord (testados 1.15.3 do stable e 1.15.4 do unstable): o patcher
    #   quebra no bundle do 1.0.138 ("i.A is not a constructor"), o renderer
    #   nunca pinta o primeiro frame e o main process nunca chama
    #   window.show() — o splash ("Discord Updater") fica para sempre e o
    #   dash mostra o app como "starting..." eternamente (a janela principal
    #   nunca aparece). Não é o config do usuário: reproduz com ~/.config/discord
    #   zerado.
    #
    # Reative `withVencord = true` quando sair um Vencord compatível com o
    # bundle do 1.0.138. Até lá os plugins de UI (NoTrack, esconder Nitro
    # upsell) ficam desligados.
    #
    # O pacote é unfree (nixpkgs.config.allowUnfree = true em
    # modules/nixos/common.nix) e o id do .desktop é `discord.desktop`
    # (name = pname em makeDesktopItem, StartupWMClass=discord) — é esse id que
    # vai no favorite-apps/auto-move-windows de home/modules/gnome.nix.
    discord
  ];

  # Ícone do och no GNOME: o pacote instala och.png em share/icons/hicolor,
  # mas o home-manager não gera o icon-theme.cache do hicolor no profile — e o
  # GNOME às vezes não resolve ícones de pacote sem o cache (fica o ícone
  # genérico). Copiar para ~/.local/share/icons (XDG_DATA_HOME, sempre varrido)
  # garante que o app apareça com ícone no grid/dock.
  xdg.dataFile."icons/hicolor/512x512/apps/och.png".source =
    "${pkgs.och}/share/icons/hicolor/512x512/apps/och.png";

  # Native messaging do 1Password: arquivo no diretório que o Firefox lê.
  #
  # Não vai pelo `mozilla.firefoxNativeMessagingHosts`: essa opção já está
  # ocupada pelo próprio pacote do Firefox (o HM põe `pkgs.firefox` na lista),
  # então um arquivo avulso é mais direto e não mexe na lista existente.
  home.file.".mozilla/native-messaging-hosts/com.1password.1password.json".source =
    onepassword-native-host;

  # Início automático no login. O GNOME lê $XDG_CONFIG_HOME/autostart (spec
  # XDG), então uma entrada basta.
  #
  # O 1Password tem o toggle "Open 1Password automatically when I sign in to
  # my computer" na UI, mas a entrada é declarada aqui de qualquer forma:
  # fica versionada no repo e funciona desde o primeiro login, sem depender
  # do app gravar em ~/.config/autostart por conta própria.
  #
  # `entries` aponta para o .desktop do pacote (instalado pelo módulo
  # programs._1password-gui em modules/nixos/desktop.nix) em vez de uma cópia
  # escrita à mão: nada para manter em sincronia com o upstream, e o
  # `Exec=1password %U` já resolve no PATH do sistema.
  xdg.autostart = {
    enable = true;
    entries = [ "${pkgs._1password-gui}/share/applications/1password.desktop" ];
  };

  # Player de vídeo com aceleração de hardware na RX 7600 (VAAPI)
  programs.mpv = {
    enable = true;
    config = {
      hwdec = "auto-safe";
      vo = "gpu";
    };
  };

  programs.firefox = {
    enable = true;
    languagePacks = [ "pt-BR" ];

    # Políticas (policies.json) — valem para todos os perfis
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFormHistory = true;
      DontCheckDefaultBrowser = true;
      PasswordManagerEnabled = false; # o 1Password é o gerenciador
    };

    profiles.lafco = {
      id = 0;
      name = "lafco";
      isDefault = true;

      search = {
        force = true;
        default = "ddg";
        privateDefault = "ddg";
      };

      settings = {
        "widget.use-xdg-desktop-portal.file-picker" = 1; # file picker via portal (qualquer WM)
        "browser.toolbars.bookmarks.visibility" = "never";
        "extensions.pocket.enabled" = false;
        "browser.startup.homepage" = "about:home";
        # As extensões em <perfil>/extensions são "sideload": sem isto o
        # Firefox pede habilitação manual na primeira execução.
        "extensions.autoDisableScopes" = 0;
        # Necessário para o Firefox ler chrome/userContent.css — o HM escreve
        # o arquivo mas NÃO liga este pref.
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };

      # Ocultação da UI de Shorts — complementa os filtros do uBlock Origin.
      userContent = shortsCss;

      # Preferências da extensão gravadas declarativamente pelo HM em
      # browser-extension-data/<id>/storage.js (storage.local, JSON).
      # `force = true` é OBRIGATÓRIO: `extensions.settings` substitui o
      # storage.local inteiro da extensão (assertion do módulo do HM).
      extensions.settings."${ublock-origin-id}" = {
        force = true;
        settings."user-filters" = shortsFilters;
      };

      extensions.packages = [
        ublock-origin-extension
        onepassword-extension
        pywalfox-extension
      ];
    };
  };
}
