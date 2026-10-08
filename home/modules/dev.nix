# Runtimes e ferramentas de desenvolvimento (core — todas as máquinas).
#
# nodejs_22 e python3 também são usados pelos plugins do nvim (editor.nix);
# repetir aqui é inofensivo e deixa a intenção explícita.
#
# Rust: toolchain estável do nixpkgs (cargo/rustc/rustfmt/clippy). Se um dia
# precisar de múltiplas toolchains/rustup, troque por:
#   rustup  # + variáveis RUSTUP_HOME/CARGO_HOME e PATH ~/.cargo/bin
#
# Tauri v2: a seção no fim do arquivo traz a stack nativa (WebKitGTK 4.1) e as
# variáveis de ambiente sem as quais o `cargo build` não acha as libs.
{ pkgs, lib, ... }:
let
  # Tauri v2 no Linux: a stack que o WebKitGTK 4.1 puxa. Os outputs `dev` são
  # instalados junto porque headers e .pc vivem lá, e o pkg-config do nixpkgs
  # NÃO procura no perfil — só no que estiver em PKG_CONFIG_PATH (ver
  # systemd.user.sessionVariables no fim do arquivo).
  tauriLibs = with pkgs; [
    webkitgtk_4_1 # WebView; o javascriptcoregtk-4.1.pc vem junto
    gtk3
    libsoup_3
    librsvg
    glib
    glib-networking # TLS dentro do WebView
    gdk-pixbuf
    cairo
    pango
    harfbuzz
    at-spi2-atk # traz atk.pc, exigido por gtk+-3.0.pc
    zlib # exigido por gdk-3.0.pc (Requires, não Requires.private)

    # extras que o guia de pré-requisitos do Tauri v2 pede no Linux
    libayatana-appindicator # tray icon
    libayatana-indicator # ayatana-indicator3-0.4.pc, exigido pelo anterior
    libdbusmenu # dbusmenu-glib-0.4.pc, idem
    ayatana-ido # ayatana-ido3-0.4.pc, idem
    openssl
    xdo # libxdo (não publica .pc; entra pelo runtime)
    alsa-lib
    gsettings-desktop-schemas # schemas do GTK (runtime; não publica .pc)
  ];
  tauriDev = map lib.getDev tauriLibs;
in
{
  home.packages =
    with pkgs;
    [
      # rust
      cargo
      rustc
      rustfmt
      clippy

      # javascript/typescript
      nodejs_22
      pnpm
      deno
      bun

      # python
      python3

      # banco de dados (cliente psql; o SERVIDOR fica em modules/nixos/database.nix)
      postgresql

      # dotfiles: no NixOS os symlinks vêm do home-manager (dotfiles.nix); o stow
      # fica para uso manual e para o CLI `dot` do repo lafco/config.
      stow
    ]
    ++ [
      # tauri v2 — CLI + build nativo
      cargo-tauri # `cargo tauri` (2.x)
      pkg-config # resolve os .pc das libs abaixo durante o build
    ];

  # As libs do Tauri NÃO entram em home.packages: PKG_CONFIG_PATH e
  # LD_LIBRARY_PATH apontam direto para os store paths, e instalar os 40
  # outputs no perfil quebra o pkgs.buildEnv — gdk-pixbuf e librsvg publicam o
  # mesmo `lib/gdk-pixbuf-2.0/2.10.0/loaders.cache` (buildEnv recusa dois paths
  # com o mesmo subpath). Os outputs `dev` são referenciados pelo texto do
  # environment.d, e isso já basta para mantê-los no closure.

  # PKG_CONFIG_PATH/LD_LIBRARY_PATH vão aqui e não em home.sessionVariables:
  # nenhum shell desta máquina lê hm-session-vars.sh (não existe ~/.profile, e o
  # ~/.bash_profile do repo só faz source do .bashrc). O env do systemd --user
  # vira environment.d, que a sessão gráfica carrega e os terminais herdam.
  # Trocar isto exige logout/login para valer.
  systemd.user.sessionVariables = {
    # Os dois diretórios: o setup-hook do pkg-config do nixpkgs procura em
    # `lib/pkgconfig` E `share/pkgconfig` — o zlib, por exemplo, só publica
    # `zlib.pc` em share/, e o gdk-3.0.pc exige zlib. Só lib/ faz o
    # `--cflags --libs` do webkit2gtk-4.1 falhar.
    PKG_CONFIG_PATH = lib.concatStringsSep ":" (
      lib.concatMap (p: [
        "${p}/lib/pkgconfig"
        "${p}/share/pkgconfig"
      ]) tauriDev
    );
    LD_LIBRARY_PATH = lib.makeLibraryPath tauriLibs;
  };
}
