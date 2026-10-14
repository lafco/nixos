# OpenCode v2 (série 2.0.x, do anomalyco/opencode — ex-sst/opencode).
#
# Por que não vem do nixpkgs: o `opencode` do nixpkgs ainda é a série 1.x
# (estável 26.05: 1.15.10; unstable: 1.18.35) e o `opencode2` está em PR aberto
# (NixOS/nixpkgs#569770, init em 2.0.26). Enquanto isso, este pacote usa o
# binário pré-compilado publicado no npm oficial — o mesmo que o instalador
# `curl -fsSL https://opencode.ai/install` baixa.
#
# É o build glibc (não o musl) e o tarball só traz `package/bin/opencode`; o
# wrapper `@opencode/cli` reexporta esse arquivo como `opencode` e `opencode2`.
# O binário do NixOS não roda sem patchelf (interpreter `/lib64/ld-linux-*.so.2`
# é um stub-ld lá), mas o `autoPatchelfHook` NÃO serve: ele reescreve o ELF e o
# binário — que é compilado com bun e se relê pelo próprio arquivo — passa a se
# comportar como o `bun` puro (`--version` -> 1.4.2, `--help` -> help do bun).
# Só o interpreter precisa ser trocado: as libs (libc/libm/libdl/libpthread)
# são achadas pelo loader do glibc do nix. Mesmo motivo do `dontStrip`.
#
# Bump manual:
#   1. última versão: `npm view @opencode/cli dist-tags.latest`
#      (ou https://registry.npmjs.org/@opencode/cli);
#   2. hash novo:
#      nix store prefetch-file --json --hash-type sha256 \
#        https://registry.npmjs.org/@opencode/cli-linux-x64/-/cli-linux-x64-<versão>.tgz
#   3. atualize `version` e `hash` abaixo.
{
  lib,
  stdenv,
  fetchurl,
  glibc,
  makeBinaryWrapper,
  patchelf,
  ripgrep,
  wayland,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "opencode-v2";
  version = "2.0.29";

  src = fetchurl {
    url = "https://registry.npmjs.org/@opencode/cli-linux-x64/-/cli-linux-x64-${finalAttrs.version}.tgz";
    hash = "sha256-FLWmY4oaCTrJ1IRZnIRLEMKbRF0EhEtoLMxmjOJlMKI=";
  };

  nativeBuildInputs = [
    makeBinaryWrapper
    patchelf
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/opencode $out/bin/opencode
    patchelf --set-interpreter ${glibc}/lib/ld-linux-x86-64.so.2 $out/bin/opencode
    # Nome alternativo exposto pelo pacote npm oficial: deixa os dois conviverem
    # caso o `opencode` v1 do nixpkgs entre na config depois.
    ln -s opencode $out/bin/opencode2

    runHook postInstall
  '';

  # O binário é compilado com o bun e se relê via /proc/self/exe, então o
  # wrapper tem que ser o makeBinaryWrapper (exec real, não script).
  # ripgrep: o CLI chama `rg` (grep de arquivos).
  # wayland: OpenTUI faz dlopen para colar imagem do clipboard (mesmo motivo do
  # PR do nixpkgs). OPENCODE_DISABLE_AUTOUPDATE: senão ele tenta se atualizar
  # por fora do Nix.
  postFixup = ''
    wrapProgram $out/bin/opencode \
      --prefix PATH : ${lib.makeBinPath [ ripgrep ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ wayland ]} \
      --set OPENCODE_DISABLE_AUTOUPDATE true
  '';

  meta = {
    description = "The open source AI coding agent (v2)";
    homepage = "https://opencode.ai";
    changelog = "https://github.com/anomalyco/opencode/blob/dev/CHANGELOG.md";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "opencode";
  };
})
