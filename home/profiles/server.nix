# Perfil do SERVIDOR headless (SSH-only, enxuto).
# O core (shell, git, editor, terminal, direnv) já vem de home/lafco;
# adicione aqui apenas o que for específico do servidor.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # ex.: ferramentas de deploy/observabilidade que você usa no servidor
  ];
}
