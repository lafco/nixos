# T3 Code desktop (Electron) — AppImage do release oficial do GitHub.
#
# Projeto: pingdotgg/t3code (MIT, https://t3.codes), app desktop para coding
# agents do time do T3 (T3 Chat). Não existe no nixpkgs.
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
# Bump manual:
#   1. última versão: `gh release view --repo pingdotgg/t3code`
#      (asset `T3-Code-<versão>-x86_64.AppImage`);
#   2. hash: nix store prefetch-file --json --hash-type sha256 <url>;
#   3. atualize `version` e `hash` abaixo.
{
  lib,
  appimageTools,
  fetchurl,
}:
let
  pname = "t3code";
  version = "0.1.9";
  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    hash = "sha256-0KtW3z4zjyQoSENWISl/2WOjNxWw2CCNvwg5lllXLYE=";
  };
  contents = appimageTools.extract { inherit pname version src; };

  # .desktop próprio em vez do upstream (que traz Exec=AppRun %U): Exec com
  # --no-sandbox (chrome-sandbox sem setuid no store) e updater desligado via
  # env. StartupWMClass e MimeType vêm do .desktop do upstream.
  desktopFile = builtins.toFile "t3code.desktop" ''
    [Desktop Entry]
    Name=T3 Code
    Exec=env T3CODE_DISABLE_AUTO_UPDATE=1 t3code --no-sandbox %U
    Terminal=false
    Type=Application
    Icon=t3code
    StartupWMClass=t3code
    Comment=Desktop app for coding agents
    MimeType=x-scheme-handler/t3code;x-scheme-handler/t3code-dev;
    Categories=Development;
  '';
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = contents;

  extraInstallCommands = ''
    install -m 444 -D ${desktopFile} $out/share/applications/t3code.desktop

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
