# Agentes de IA: pi (pi.dev) + herdr (app desktop + core)
# Todos só existem no nixpkgs-unstable — vêm do overlay em lib/overlays.nix.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    unstable.pi-coding-agent # pi
    unstable.herdr-desktop # app desktop (`herdr-app`), com .desktop e ícone
    unstable.herdr-core # backend (`hc`), que hospeda os terminais; o app o procura em /nix/store
    pkgs.opencode-v2 # OpenCode v2 (binários `opencode` e `opencode2`)
  ];

  # App no login: com a janela já aberta, o Super+Return (favorito 1 do dash,
  # ver gnome.nix) só foca. Ele sobe o herdr-core, que é o mesmo core que o
  # celular alcança por SSH (`hc`), então o ambiente está de pé sem abrir nada
  # à mão. `entries` é lista: soma com o 1Password declarado em apps.nix.
  xdg.autostart.entries = [
    "${pkgs.unstable.herdr-desktop}/share/applications/herdr-app.desktop"
  ];

  # Quem mantém os terminais vivos é o herdr-core (socket em
  # $XDG_RUNTIME_DIR/herdr-core/default.sock), que o app sobe ao abrir e que o
  # `hc` sobe sozinho quando alguém chama de um SSH. Ele não precisa de unit
  # própria: o lingering (users.users.lafco.linger no host daily) mantém o user
  # manager de pé, e o core sobrevive ao fechar a janela. Acesso pelo celular:
  # ver o cabeçalho de modules/nixos/remote.nix.
}
