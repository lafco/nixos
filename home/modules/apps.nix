# Apps de desktop: Firefox (declarativo) + Proton Pass
# Firefox: extensões e preferências versionadas; login/sync continua manual (1x).
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
  #     integrações dependem do ID real do AMO (native messaging do Proton Pass
  #     ↔ app desktop e do Pywalfox ↔ CLI, e o próprio Firefox Sync).
  # O nome leva sufixo `-extension` de propósito: um binding `proton-pass`
  # aqui sombrearia o `pkgs.proton-pass` do `with pkgs` em home.packages.
  ublock-origin-extension = pkgs.firefox-addons.ublock-origin;
  proton-pass-extension = pkgs.firefox-addons.proton-pass;
  pywalfox-extension = pkgs.firefox-addons.pywalfox; # tema do Firefox seguindo a paleta do Noctalia

  # ID canônico da extensão (é ele que o Firefox usa em
  # browser-extension-data/<id>/). O pacote do overlay expõe `addonId`; o
  # fetchFirefoxAddon do nixpkgs expõe `extid` — aceitamos os dois.
  ublock-origin-id = ublock-origin-extension.extid or ublock-origin-extension.addonId;

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
    pkgs.proton-pass # app desktop do Proton Pass (Linux) — NÃO é a extensão
    obsidian # notas — template de tema disponível no Noctalia
    # O updater interno é desativado pelo overlay: o AppImage fica imutável no
    # /nix/store e novas versões são aplicadas pelo flake/Nix.
    ankama-launcher # jogos Ankama (Dofus, Waven, Wakfu…) — AppImage + wine
  ];

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
      PasswordManagerEnabled = false; # o Proton Pass é o gerenciador
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
        proton-pass-extension
        pywalfox-extension
      ];
    };
  };
}
