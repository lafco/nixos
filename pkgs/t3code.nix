# T3 Code desktop (Electron) — AppImage do release do nosso repo.
#
# Projeto original: pingdotgg/t3code (MIT, https://t3.codes), app desktop para
# coding agents do time do T3 (T3 Chat). Não existe no nixpkgs. Este pacote usa
# o build do nosso repositório: lafco/czede — base achatada no upstream v0.1.9,
# onde ficam as modificações. O AppImage é gerado pelo workflow
# `.github/workflows/release-appimage.yml` do próprio czede (runner hospedado do
# GitHub), que publica `T3-Code-<versão>-x86_64.AppImage` no release do tag.
#
# Por que extract + wrapAppImage e não wrapType2: o `wrapAppImage` do nixpkgs
# extrai o AppImage em ~/.cache/appimage-run na primeira execução — extraindo
# no build, o primeiro start é imediato e o conteúdo fica determinístico no
# /nix/store (mesmo padrão do pacote openchamber que este repo tinha).
#
# Limitações em NixOS:
#   - o updater interno (electron-updater, `resources/app-update.yml`) não
#     consegue escrever em /nix/store — o .desktop executa com
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
  appimageTools,
  fetchurl,
}:
let
  pname = "t3code";
  version = "0.1.9-fork.3";
  src = fetchurl {
    url = "https://github.com/lafco/czede/releases/download/v${version}/czede-${version}-x86_64.AppImage";
    hash = "sha256-PeanaaI3lxN+u/PcUaG4U1+wHiTZoCbNnbkRiIuAXIw=";
  };
  contents = appimageTools.extract { inherit pname version src; };

  # .desktop próprio em vez do que o AppImage traz (Exec=AppRun %U): Exec com
  # --no-sandbox (chrome-sandbox sem setuid no store) e updater desligado via
  # env. O binário dentro do AppImage continua `t3code` (é o executableName do
  # electron-builder, e o ícone acompanha: hicolor/*/apps/t3code.png).
  # StartupWMClass casa com o app.setDesktopName do app:
  # com.lafco.czede.desktop -> WM_CLASS com.lafco.czede.
  desktopFile = builtins.toFile "czede.desktop" ''
    [Desktop Entry]
    Name=czede
    Exec=env T3CODE_DISABLE_AUTO_UPDATE=1 t3code --no-sandbox %U
    Terminal=false
    Type=Application
    Icon=t3code
    StartupWMClass=com.lafco.czede
    Comment=Desktop app for coding agents
    MimeType=x-scheme-handler/czede;x-scheme-handler/czede-dev;
    Categories=Development;
  '';
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = contents;

  extraInstallCommands = ''
    install -m 444 -D ${desktopFile} $out/share/applications/czede.desktop

    # Ícones em todos os tamanhos que o AppImage traz (16..512). O mkdir é
    # necessário: `cp -r src dest/` com dest inexistente ACHATA o conteúdo da
    # fonte no destino (comportamento do cp do coreutils), sumindo com o
    # nível `hicolor/` que o GNOME espera.
    mkdir -p $out/share/icons/hicolor
    cp -r ${contents}/usr/share/icons/hicolor/. $out/share/icons/hicolor/
  '';

  meta = {
    description = "Desktop app for coding agents (T3 Code)";
    homepage = "https://t3.codes";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "t3code";
  };
}
