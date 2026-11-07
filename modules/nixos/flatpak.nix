# Flatpak declarativo (nix-flatpak) para o host daily.
#
# O módulo flatpak do nixpkgs só instala o flatpak e o portal de desktop; o
# nix-flatpak (input do flake) adiciona `services.flatpak.packages`/`remotes` e
# um serviço systemd que roda o `flatpak install` na ativação.
#
# O Deadlock Mod Manager não está no Flathub: o bundle do release v1.1.0 é
# baixado do GitHub por hash (URL imutável) e instalado direto. O runtime
# org.gnome.Platform//49 que ele exige vem do Flathub e é declarado aqui para
# não depender da resolução automática de dependência do bundle.
{ pkgs, ... }:
let
  deadlockVersion = "v1.1.0";
  # sha256 do bundle (release v1.1.0). SRI gerado com:
  # nix hash file --type sha256 --sri deadlock-mod-manager.flatpak
  deadlockSha256 = "sha256-1A67ZJpQyjKrd1EkvhR5XErnz7FYkYSVY8QLhY9k//U=";
  deadlockBundle = pkgs.fetchurl {
    url = "https://github.com/deadlock-mod-manager/deadlock-mod-manager/releases/download/${deadlockVersion}/deadlock-mod-manager.flatpak";
    hash = deadlockSha256;
  };
in
{
  services.flatpak = {
    enable = true;
    packages = [
      # Runtime exigido pelo bundle (org.gnome.Platform/x86_64/49).
      "org.gnome.Platform//49"
      {
        appId = "dev.stormix.deadlock-mod-manager";
        bundle = "${deadlockBundle}";
        sha256 = deadlockSha256;
      }
    ];
  };
}
