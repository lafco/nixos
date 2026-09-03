# Overlays compartilhados entre os hosts NixOS e o home-manager standalone.
{ inputs }:
[
  # Pacotes do unstable acessíveis como pkgs.unstable.* (usado pelo
  # ai.nix do repo de dotfiles: pi-coding-agent, herdr).
  (final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = prev.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  })

  # Compat: o repo de dotfiles (github:lafco/config) ainda usa
  # nodePackages.intelephense, mas `nodePackages` foi REMOVIDO do nixpkgs em
  # 2026 (intelephense virou atributo top-level). Este shim mantém o módulo
  # deles funcionando sem fork — remova quando o repo deles atualizar.
  (final: prev: {
    nodePackages = {
      inherit (prev) intelephense;
    };
  })
]
