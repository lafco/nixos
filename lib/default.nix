# Helpers compartilhados por todo o flake.
let
  systems = [ "x86_64-linux" "aarch64-linux" ];
in
{
  # Nome do usuário principal — troque aqui e nos arquivos que o referenciam.
  userName = "lafco";

  inherit systems;

  # Aplica `f` a cada sistema suportado e devolve { "<system>" = f "<system>"; }.
  forAllSystems = f: builtins.listToAttrs (map (s: { name = s; value = f s; }) systems);
}
