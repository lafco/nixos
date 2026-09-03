# direnv + nix-direnv: carrega devShells automaticamente por diretório.
{ ... }:
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
