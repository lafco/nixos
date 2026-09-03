# Overlays compartilhados entre os hosts NixOS e o home-manager standalone.
{ inputs }:
[
  # Pacotes do unstable acessíveis como pkgs.unstable.* (usado por
  # home/modules/ai.nix: pi-coding-agent, herdr).
  (final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = prev.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  })
]
