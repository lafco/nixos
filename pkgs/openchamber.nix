# OpenChamber desktop (Electron) — AppImage do release oficial do GitHub.
#
# Não existe no nixpkgs (o projeto publica só binários: deb/rpm/AppImage para
# desktop, e o CLI/servidor web como pacote npm `@openchamber/web`).
#
# Por que extract + wrapAppImage e não wrapType2: o `wrapAppImage` do nixpkgs
# extrai o AppImage em ~/.cache/appimage-run na primeira execução — aqui isso
# custa ~1 GB, porque o app embute o binário do OpenCode CLI (247 MB) e o
# web-dist (62 MB). Extraindo no build, o primeiro start é imediato e o
# conteúdo fica determinístico no /nix/store.
#
# Limitações em NixOS:
#   - o updater interno (electron-updater, `resources/app-update.yml`) não
#     consegue escrever em /nix/store: atualização é bump de versão aqui;
#   - o `chrome-sandbox` da AppImage não pode ser setuid no store, então o
#     .desktop chama com `--no-sandbox` (como o .desktop do upstream).
#
# Bump manual:
#   1. última versão: `gh release view --repo openchamber/openchamber`
#      (asset `OpenChamber-<versão>-linux-x86_64.AppImage`);
#   2. hash: nix store prefetch-file --json --hash-type sha256 <url>;
#   3. atualize `version` e `hash` abaixo.
{
  lib,
  appimageTools,
  fetchurl,
}:
let
  pname = "openchamber";
  version = "2.7.0";
  src = fetchurl {
    url = "https://github.com/openchamber/openchamber/releases/download/v${version}/OpenChamber-${version}-linux-x86_64.AppImage";
    hash = "sha256-EaUrzL+9AKp7WmbvSBGd92uM/yWfruR0mWR6AsGbtAE=";
  };
  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = contents;

  # A AppImage traz `openchamber.desktop` e um ícone 512x512 em
  # usr/share/icons; o `.desktop` aponta para `AppRun`, então o Exec é trocado
  # para o binário do wrapper (mesmo padrão do upstream, mantendo --no-sandbox).
  extraInstallCommands = ''
    install -m 444 -D ${contents}/openchamber.desktop $out/share/applications/openchamber.desktop
    substituteInPlace $out/share/applications/openchamber.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=openchamber --no-sandbox %U'

    install -m 444 -D ${contents}/usr/share/icons/hicolor/512x512/apps/openchamber.png \
      $out/share/icons/hicolor/512x512/apps/openchamber.png
  '';

  meta = {
    description = "Agentic development environment built on the OpenCode AI agent";
    homepage = "https://openchamber.dev/";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "openchamber";
  };
}
