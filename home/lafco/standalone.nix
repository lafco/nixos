# Identidade do usuário para o modo STANDALONE (máquina da empresa).
# O home-manager 26.05 não infere mais home.username pelo nome da
# configuração ("lafco@work") — declaramos explicitamente.
{ ... }:
{
  home.username = "lafco";
  home.homeDirectory = "/home/lafco"; # macOS: troque para /Users/lafco
}
