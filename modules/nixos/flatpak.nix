# Flatpak declarativo (nix-flatpak) para o host daily.
#
# O módulo flatpak do nixpkgs só instala o flatpak e o portal de desktop; o
# nix-flatpak (input do flake) adiciona `services.flatpak.packages`/`remotes` e
# um serviço systemd que roda o `flatpak install` na ativação.
#
# Nenhum app é gerenciado declarativamente por enquanto: com o flatpak ligado,
# o GNOME Software assume o papel de instalar/atualizar os apps do Flathub
# manualmente. Quando quiser declarar algum, adicione o appId em `packages`.
{ ... }:
{
  services.flatpak = {
    enable = true;
    packages = [ ];
  };
}
