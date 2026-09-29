# Spotify oficial com Spicetify (tema + extensões), via o input
# `spicetify-nix` (github:Gerg-L/spicetify-nix). Só faz sentido nas máquinas
# com desktop — é importado por home/profiles/personal.nix, não pelo core.
#
# `programs.spicetify.enable = true` já instala o Spotify "spiced" (o pacote
# original com as modificações aplicadas no build) em home.packages. NÃO
# adicionar `pkgs.spotify` em paralelo: seriam duas entradas no menu de apps,
# e a doc do módulo pede explicitamente para não instalá-lo à mão.
#
# Detalhes do que fica versionado aqui:
#  - o tema é extraído do catálogo do spicetify-nix (pinado no flake.lock);
#  - as extensões vêm dos sources do spicetify-nix (fetchGit pinado lá).
#  - o resto (login, playlists, prefs) continua no estado do próprio Spotify,
#    não no repo.
{ pkgs, inputs, ... }:
let
  # O `legacyPackages` do spicetify-nix constrói o Spotify com um nixpkgs em
  # que só o pacote `spotify` é liberado (allowUnfreePredicate). O
  # `follows = "nixpkgs"` no flake garante que esse nixpkgs é o MESMO do
  # sistema.
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];

  programs.spicetify = {
    enable = true;

    # Tema catppuccin: o colorScheme abaixo precisa ser uma das seções do
    # Themes/catppuccin/color.ini (mocha, macchiato, frappe, latte) — o build
    # falha explicitamente se o valor não existir.
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";

    enabledExtensions = with spicePkgs.extensions; [
      adblockify # bloqueia os anúncios (útil no plano free)
      hidePodcasts # tira podcasts da home/busca
      volumePercentage # mostra o volume em % no controle
      beautifulLyrics # letra sincronizada
    ];

    # EXPERIMENTO — Wayland nativo no GNOME.
    # `wayland = true` faz o builder embrulhar o binário com
    # `--ozone-platform=wayland`. O flag é INCONDICIONAL: na sessão XFCE (X11,
    # sem compositor Wayland) o Spotify não inicia. Enquanto isto estiver
    # ligado, o Spotify só funciona na sessão do GNOME.
    #
    # Motivo: sob XWayland o Spotify é ativado com um round trip de
    # des-iconificar/repintar do CEF, que é o candidato a atraso no Super+M.
    # Se não houver ganho perceptível, reverter = `wayland = null` (o default,
    # que deixa o Chromium escolher sozinho a partir do DISPLAY).
    wayland = true;
  };
}
