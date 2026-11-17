# czede desktop (Electron) — AppImage do release do nosso repo.
#
# Projeto original: pingdotgg/t3code (MIT, https://t3.codes), app desktop para
# coding agents do time do T3 (T3 Chat). Não existe no nixpkgs. Este pacote usa
# o build do nosso repositório: lafco/czede — base achatada no upstream v0.1.9,
# onde ficam as modificações. O AppImage é gerado pelo workflow
# `.github/workflows/release-appimage.yml` do próprio czede (runner hospedado do
# GitHub), que publica `czede-<versão>-x86_64.AppImage` no release do tag.
#
# Por que extract + wrapper próprio e NÃO `appimageTools.wrapAppImage`:
#   - `wrapAppImage` embrulha o app num `buildFHSEnv`, isto é, bubblewrap. Dentro
#     desse sandbox o `sudo` não funciona: o bwrap liga PR_SET_NO_NEW_PRIVS, e o
#     sudo recusa ("The 'no new privileges' flag is set"). Como esta máquina usa
#     o czede para rodar agentes e shells, o terminal do app precisa de sudo
#     como qualquer outro terminal;
#   - extraindo o AppImage no build e executando o binário direto, com as libs
#     do nixpkgs em LD_LIBRARY_PATH, o app roda sem sandbox — igual ao .deb e ao
#     AppImage oficiais — e o primeiro start continua imediato.
#
# Limitações em NixOS:
#   - o updater interno (electron-updater, `resources/app-update.yml`) não
#     consegue escrever em /nix/store — o wrapper exporta
#     `T3CODE_DISABLE_AUTO_UPDATE=1` (chave oficial do app; o flake da
#     comunidade t3code-flake usa a mesma). Atualização é bump de versão aqui;
#   - o `chrome-sandbox` da AppImage não pode ser setuid no store, então o
#     .desktop chama com `--no-sandbox` (como o launcher do AUR);
#   - o app roda via XWayland por padrão; para Wayland nativo, o PKGBUILD do
#     AUR passa `--enable-features=UseOzonePlatform --ozone-platform=wayland`.
#
# Bump manual (a partir do repo czede):
#   1. tag nova: `git tag -a v<versão>-fork.<n> -m ... && git push origin <tag>`
#      — o workflow builda e publica o AppImage no release do tag;
#   2. versão publicada: `gh release list --repo lafco/czede`
#      (asset `czede-<versão>-x86_64.AppImage`);
#   3. hash: nix store prefetch-file --json --hash-type sha256 <url>;
#   4. atualize `version` e `hash` abaixo.
{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
  makeWrapper,
  gtk3,
  glib,
  nss,
  nspr,
  alsa-lib,
  libgbm,
  libdrm,
  mesa,
  libxkbcommon,
  at-spi2-core,
  cups,
  libsecret,
  libnotify,
  libappindicator-gtk3,
  dbus,
  expat,
  systemd,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxcb,
  libxshmfence,
  pango,
  cairo,
  gdk-pixbuf,
  harfbuzz,
  util-linux,
}:
let
  pname = "t3code";
  version = "0.1.9-fork.4";
  src = fetchurl {
    url = "https://github.com/lafco/czede/releases/download/v${version}/czede-${version}-x86_64.AppImage";
    hash = "sha256-5g93RdB7CcFDhvYoBALt8OWC+U34vHPRgxnrx0Zddmw=";
  };
  contents = appimageTools.extract { inherit pname version src; };

  # O que o Chromium/Electron carrega em runtime e que o NixOS não tem em /lib.
  # A lista é a mesma que os pacotes de Electron do nixpkgs usam; faltando algo,
  # o app falha no start com "error while loading shared libraries".
  runtimeLibs = [
    gtk3
    glib
    nss
    nspr
    alsa-lib
    libgbm
    libdrm
    mesa
    libxkbcommon
    at-spi2-core
    cups
    libsecret
    libnotify
    libappindicator-gtk3
    dbus
    expat
    systemd
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    libxshmfence
    pango
    cairo
    gdk-pixbuf
    harfbuzz
    util-linux
  ];

  # .desktop próprio em vez do que o AppImage traz (Exec=AppRun %U): Exec com
  # --no-sandbox (chrome-sandbox sem setuid no store) e updater desligado via
  # env. O binário dentro do AppImage continua `t3code` (é o executableName do
  # electron-builder, e o ícone acompanha: hicolor/*/apps/t3code.png).
  # StartupWMClass casa com o app.setDesktopName do app:
  # com.lafco.czede.desktop -> WM_CLASS com.lafco.czede.
  desktopFile = builtins.toFile "czede.desktop" ''
    [Desktop Entry]
    Name=czede
    Exec=t3code --no-sandbox %U
    Terminal=false
    Type=Application
    Icon=t3code
    StartupWMClass=com.lafco.czede
    Comment=Desktop app for coding agents
    MimeType=x-scheme-handler/czede;x-scheme-handler/czede-dev;
    Categories=Development;
  '';
in
stdenv.mkDerivation {
  inherit pname version;

  nativeBuildInputs = [ makeWrapper ];

  # Nada a compilar: o AppImage já vem pronto, o que se faz aqui é reorganizar
  # e embrulhar.
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec
    cp -r ${contents}/. $out/libexec/

    # Wrapper no lugar do AppRun: mesmo env que o AppRun monta (APPDIR no PATH,
    # XDG_DATA_DIRS e GSETTINGS_SCHEMA_DIR da árvore extraída, libs do AppImage
    # em LD_LIBRARY_PATH) mais as libs do nixpkgs.
    mkdir -p $out/bin
    makeWrapper $out/libexec/t3code $out/bin/t3code \
      --prefix LD_LIBRARY_PATH : "$out/libexec/usr/lib:${lib.makeLibraryPath runtimeLibs}" \
      --prefix PATH : "$out/libexec:$out/libexec/usr/sbin" \
      --prefix XDG_DATA_DIRS : "$out/libexec/usr/share" \
      --set-default GSETTINGS_SCHEMA_DIR "$out/libexec/usr/share/glib-2.0/schemas" \
      --set-default T3CODE_DISABLE_AUTO_UPDATE "1"

    install -m 444 -D ${desktopFile} $out/share/applications/czede.desktop

    # Ícones em todos os tamanhos que o AppImage traz (16..512). O mkdir é
    # necessário: `cp -r src dest/` com dest inexistente ACHATA o conteúdo da
    # fonte no destino (comportamento do cp do coreutils), sumindo com o
    # nível `hicolor/` que o GNOME espera.
    mkdir -p $out/share/icons/hicolor
    cp -r ${contents}/usr/share/icons/hicolor/. $out/share/icons/hicolor/

    runHook postInstall
  '';

  meta = {
    description = "Desktop app for coding agents (czede), sem sandbox para o sudo funcionar";
    homepage = "https://github.com/lafco/czede";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "t3code";
  };
}
