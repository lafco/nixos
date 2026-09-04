# Overlays compartilhados entre os hosts NixOS e o home-manager standalone.
{ inputs }:
[
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
    in
    {
      ankama-launcher = ankamaLauncher;

      unstable = import inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    }
  )
]
