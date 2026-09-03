# Perfil da MÁQUINA DA EMPRESA (home-manager standalone em Ubuntu/Debian).
#
# É importado DEPOIS de home/lafco, então as opções daqui sobrescrevem as
# do core (mkForce vence a identidade git definida pelo repo de dotfiles).
{ pkgs, lib, ... }:
{
  programs.git.settings = {
    user = {
      name = lib.mkForce "SEU NOME"; # TODO: identidade da empresa
      email = lib.mkForce "voce@empresa.com"; # TODO
    };
    # Git "vira" outra identidade dentro de ~/work/ (includeIf ignora
    # silenciosamente o arquivo se ele não existir):
    includeIf."gitdir:~/work/" = {
      path = "~/.gitconfig-work";
    };
  };

  home.packages = with pkgs; [
    # Ferramentas específicas do trabalho, ex.:
    # nodejs_20
    # python311
    # kubectl
  ];
}
