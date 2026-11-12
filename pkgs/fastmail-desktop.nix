# Fastmail desktop (AppImage oficial, Electron) — cópia do linux.nix do nixpkgs
# master com version/src/meta pinados aqui.
#
# Por que existe: o nixpkgs que este repo segue (estável 26.05 e o unstable
# pinado no flake.lock) fixa a 1.4.0, cujo AppImage a Fastmail já apagou do
# CDN — o fetch dá 404 e o pacote não builda. O master está em 1.9.0 e traz
# uma receita mais simples (sem autoPatchelfHook nem a remoção das sharp musl:
# a partir da 1.9.x o app não shipa mais esses binários), que é a de baixo.
#
# Bump manual:
#   1. curl -fsS \
#        https://dl.fastmailcdn.com/desktop/production/linux/x64/latest-linux.yml
#   2. `version` = campo `version` do yml; o campo `sha512` já É o hash em
#      base64, então o hash SRI é "sha512-" + esse valor.
# Quando o nixpkgs pinado chegar em 1.9.0 ou mais, apague este arquivo e o
# override em lib/overlays.nix e volte a usar pkgs.fastmail-desktop.
{
  lib,
  stdenv,
  appimageTools,
  asar,
  makeWrapper,
  electron,
  fetchurl,
}:
let
  pname = "fastmail-desktop";
  version = "1.9.0";
  src = fetchurl {
    url = "https://dl.fastmailcdn.com/desktop/production/linux/x64/com.fastmail.Fastmail-${version}.AppImage";
    hash = "sha512-v+y7AmElzR+399vA8821gz8a4uHJoKxW5n+/EZ/trMhzkOY8fAoKvoYbVE1SqKwOwR6toLYKsyUQIXFIeUb4TQ==";
  };
  appimageContents = appimageTools.extract { inherit pname version src; };
in
stdenv.mkDerivation (finalAttrs: {
  inherit pname version src;

  dontUnpack = true;
  dontBuild = true;

  strictDeps = true;

  nativeBuildInputs = [
    asar
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt"
    cp -r --no-preserve=mode "${appimageContents}/resources" "$out/opt/fastmail"
    asar extract "$out/opt/fastmail/app.asar" "$out/opt/fastmail/app.asar.unpacked"
    rm "$out/opt/fastmail/app.asar"

    install -Dt "$out/share/applications" "${appimageContents}/fastmail.desktop"
    substituteInPlace "$out/share/applications/fastmail.desktop" \
      --replace-fail "Exec=AppRun --no-sandbox %U" "Exec=fastmail %U" \
      --replace-fail "Name=com.fastmail.Fastmail" "Name=Fastmail"

    for res in 16 24 32 48 64 128 256 512 1024; do
      resdir="''${res}x''${res}"
      mkdir -p "$out/share/icons/hicolor/$resdir/apps"
      cp -r --no-preserve=mode \
        "${appimageContents}/usr/share/icons/hicolor/$resdir/apps/fastmail.png" \
        "$out/share/icons/hicolor/$resdir/apps/fastmail.png"
    done

    makeWrapper "${electron}/bin/electron" "$out/bin/fastmail" \
      --add-flags "$out/opt/fastmail/app.asar.unpacked" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-wayland-ime=true --wayland-text-input-version=3}}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ (lib.getLib stdenv.cc.cc) ]}" \
      --set-default ELECTRON_IS_DEV 0 \
      --inherit-argv0

    runHook postInstall
  '';

  meta = {
    description = "Dedicated desktop app for Fastmail";
    homepage = "https://www.fastmail.com/blog/desktop-app/";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    mainProgram = "fastmail";
  };
})
