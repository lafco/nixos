# Formatação centralizada: `nix fmt` formata todos os arquivos do repo.
{
  projectRootFile = "flake.nix";
  programs.nixfmt.enable = true; # formatador oficial do Nix
  programs.shfmt.enable = true; # scripts shell (scripts/)
  settings.excludes = [
    "hosts/*/hardware-configuration.nix" # arquivo gerado por máquina
  ];
}
