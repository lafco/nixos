# Och — fork/rebrand do OpenChamber desktop (Electron), AppImage do release
# do fork. O upstream é MIT (openchamber/openchamber), então o fork pode
# renomear, modificar e redistribuir — a única obrigação é manter o
# LICENSE/copyright do original no repo do fork.
#
# Fork: o pacote baixa de `${owner}/${repo}` (ver abaixo). O fork tem um
# workflow próprio de release, `release-linux.yml` (no lugar do release.yml do
# upstream, que depende de runners blacksmith e de secrets que o fork não tem):
# ele builda AppImage/.deb/.rpm no ubuntu-latest e publica o release.
#   gh workflow run release-linux.yml -R lafco/openchamber -f version=X.Y.Z
# ou `git tag vX.Y.Z && git push origin vX.Y.Z` (a tag num commit que contenha
# o workflow).
#
# Não existe no nixpkgs (o upstream publica só binários: deb/rpm/AppImage para
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
# Bump manual (ou automatizado: `./scripts/och-bump.sh <versão>`):
#   1. última versão: `gh release view --repo ${owner}/${repo}`
#      (asset `OpenChamber-<versão>-linux-x86_64.AppImage`);
#   2. hash: nix store prefetch-file --json --hash-type sha256 <url>;
#   3. atualize `version` e `hash` abaixo. O asset do fork é build próprio,
#      então o hash muda a cada bump (e quando o binário mudar com as suas
#      modificações) — recalcule sempre com o passo 2.
#
# Rebrand: o .desktop instalado usa Name=Och, Icon=och e Exec=och, mas mantém
# StartupWMClass=openchamber — o binário do Electron segue com o WM_CLASS do
# upstream (só muda recompilando o fork com outro productName), e é por ele
# que o GNOME associa a janela ao app (pin do auto-move-windows em
# home/modules/gnome.nix). Pelo mesmo motivo, o pgrep do fallback do Super+o
# segue casando `openchamber --no-sandbox`, não `och`.
{
  lib,
  appimageTools,
  fetchurl,
  owner ? "lafco",
  repo ? "openchamber",
}:
let
  pname = "och";
  version = "2.7.2";
  src = fetchurl {
    url = "https://github.com/${owner}/${repo}/releases/download/v${version}/OpenChamber-${version}-linux-x86_64.AppImage";
    hash = "sha256-agbPfTqMUo2+k9DM0+yU+qVLcDFYxzMpxuE8u+JS7zw=";
  };
  contents = appimageTools.extract { inherit pname version src; };

  # .desktop próprio em vez de remendar o do upstream (que traz
  # Exec=AppRun --no-sandbox %U): nome/ícone/Exec do rebrand, StartupWMClass
  # preservado para o GNOME continuar associando a janela ao app.
  desktopFile = builtins.toFile "och.desktop" ''
    [Desktop Entry]
    Name=Och
    Exec=och --no-sandbox %U
    Terminal=false
    Type=Application
    Icon=och
    StartupWMClass=openchamber
    Comment=openchamber
    Categories=Development;
  '';
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = contents;

  extraInstallCommands = ''
    install -m 444 -D ${desktopFile} $out/share/applications/och.desktop

    install -m 444 -D ${contents}/usr/share/icons/hicolor/512x512/apps/openchamber.png \
      $out/share/icons/hicolor/512x512/apps/och.png
  '';

  meta = {
    description = "Agentic development environment (fork do OpenChamber, em cima do OpenCode)";
    homepage = "https://github.com/${owner}/${repo}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "och";
  };
}
