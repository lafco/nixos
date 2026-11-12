# Overlays compartilhados entre os hosts NixOS e o home-manager standalone.
{ inputs }:
[
  # Extensões do Firefox (uBlock Origin) vindas do AMO — consumidas por
  # home/modules/apps.nix como pkgs.firefox-addons.<nome>.
  inputs.firefox-addons.overlays.default

  # Pacotes do unstable acessíveis como pkgs.unstable.* (usado por
  # home/modules/ai.nix: pi-coding-agent, herdr).
  (
    final: prev:
    let
      # O launcher distribuído pela Ankama tenta atualizar o próprio AppImage.
      # appimageTools, porém, extrai o AppImage para o /nix/store e o executa
      # sem APPIMAGE mutável. O updater falha antes da tela de login nesse
      # cenário; a atualização deve ser feita pelo próprio flake/Nix.
      ankamaPname = prev.ankama-launcher.pname;
      ankamaVersion = prev.ankama-launcher.version;
      ankamaSrc = prev.ankama-launcher.src;
      ankamaContents =
        final.runCommand "${ankamaPname}-${ankamaVersion}-extracted-patched"
          {
            nativeBuildInputs = [
              final.appimageTools.appimage-exec
              final.python3
            ];
          }
          ''
            appimage-exec.sh -x $out ${ankamaSrc}

            python3 - "$out/resources/app.asar" <<'PY'
            from pathlib import Path
            import sys

            app = Path(sys.argv[1])
            data = app.read_bytes()
            calls = [
                b'this.electronUpdater.checkForUpdates().catch(e=>{s.warn("[AUTO_UPDATER] cannot check for updates",e)})',
                b'this.electronUpdater.checkForUpdates().catch(t=>{e.warn("[AUTO_UPDATER] cannot check for updates",t)})',
            ]

            for old in calls:
                count = data.count(old)
                if count < 1:
                    raise SystemExit(f"expected updater call, found {count}")
                # Preserve the length: the ASAR header stores the original file
                # size and offsets of all following files.
                new = b"setTimeout(()=>{this.setHasChecked(!0),this.emit(\"update_not_available\")},0)" + b" " * (len(old) - len(b"setTimeout(()=>{this.setHasChecked(!0),this.emit(\"update_not_available\")},0)"))
                data = data.replace(old, new)

            app.write_bytes(data)
            PY
          '';
      ankamaLauncher = final.appimageTools.wrapAppImage {
        pname = ankamaPname;
        version = ankamaVersion;
        src = ankamaContents;
        extraPkgs = pkgs: [ pkgs.wine ];

        extraInstallCommands = ''
          desktop_file="${ankamaContents}/zaap.desktop"

          install -m 444 -D "$desktop_file" $out/share/applications/ankama-launcher.desktop
          sed -i 's/.*Exec.*/Exec=ankama-launcher/' $out/share/applications/ankama-launcher.desktop
          install -m 444 -D ${ankamaContents}/zaap.png $out/share/icons/hicolor/256x256/apps/zaap.png
        '';

        meta = prev.ankama-launcher.meta;
      };

      # Proton Pass: o app é distribuído como .deb versionado e o nixpkgs (tanto
      # o estável quanto o unstable pinado) fica atrás do upstream. Pinar
      # version + src aqui é o caminho para pegar correções sem esperar o
      # nixpkgs. Bump manual:
      #   1. veja a última versão estável em
      #      https://proton.me/download/PassDesktop/linux/x64/version.json
      #      (`jq -r '[.Releases[] | select(.CategoryName == "Stable")] | first | .Version'`);
      #   2. pegue o hash do deb novo:
      #      nix store prefetch-file --json --hash-type sha256 \
      #        https://proton.me/download/pass/linux/x64/proton-pass_<versão>_amd64.deb
      #   3. atualize `version` e `hash` abaixo.
      # O layout do deb (usr/lib/proton-pass/resources/app.asar) é o que o
      # linux.nix do nixpkgs espera, então só o src muda.
      protonPass = prev.proton-pass.overrideAttrs (old: rec {
        version = "1.41.1";
        src = final.fetchurl {
          url = "https://proton.me/download/pass/linux/x64/proton-pass_${version}_amd64.deb";
          hash = "sha256-vQLZtWAitEgADCsL43cafWYkZy+uvDO3FGyxd3XmXog=";
        };
      });

      # Fastmail desktop: o nixpkgs (estável 26.05 e o unstable pinado) fixa
      # 1.4.0, cujo AppImage a Fastmail já apagou do CDN (404 → build quebra).
      # O pacote local é uma cópia da receita do nixpkgs master (1.9.0). Ver
      # pkgs/fastmail-desktop.nix (instruções de bump lá).
      fastmailDesktop = final.callPackage ../pkgs/fastmail-desktop.nix { };

      # OpenChamber desktop: AppImage do release oficial. Ver
      # pkgs/openchamber.nix (limitações em NixOS + instruções de bump lá).
      openchamber = final.callPackage ../pkgs/openchamber.nix { };
    in
    {
      ankama-launcher = ankamaLauncher;
      proton-pass = protonPass;
      fastmail-desktop = fastmailDesktop;
      inherit openchamber;

      # OpenCode v2 (binário pré-compilado do npm oficial) — o nixpkgs só tem a
      # série 1.x. Consumido por home/modules/ai.nix. Ver pkgs/opencode-v2.nix.
      opencode-v2 = final.callPackage ../pkgs/opencode-v2.nix { };

      unstable = import inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    }
  )
]
