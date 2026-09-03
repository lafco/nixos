# Perfil da MÁQUINA DA EMPRESA (home-manager standalone em Ubuntu/Debian).
#
# É importado DEPOIS de home/lafco, então as opções daqui sobrescrevem as
# do core (ex.: identidade git).
{ pkgs, ... }:
{
  programs.git = {
    userName = "SEU NOME"; # TODO: identidade da empresa
    userEmail = "voce@empresa.com"; # TODO
    extraConfig = {
      # Git "vira" outra identidade dentro de ~/work/ (includeIf ignora
      # silenciosamente o arquivo se ele não existir):
      includeIf."gitdir:~/work/".path = "~/.gitconfig-work";
    };
  };

  home.packages = with pkgs; [
    # Ferramentas específicas do trabalho, ex.:
    # nodejs_20
    # python311
    # kubectl
  ];
}
