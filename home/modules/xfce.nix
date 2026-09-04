# XFCE (só na daily): configuração completa declarativa.
#
# Os XMLs em ./xfce/ são o formato do xfconf (banco de configurações do
# XFCE) e o home-manager os coloca em
# ~/.config/xfce4/xfconf/xfce-perchannel-xml/. Além deles, gerenciamos os
# launchers do painel (./xfce/panel/), o wallpaper (./xfce/backgrounds/) e
# o helpers.rc do exo (terminal padrão).
#
# ⚠️ Config declarativa: mudanças feitas pela GUI do XFCE são sobrescritas
# no próximo `switch`. Fluxo para trazer mudanças da GUI para cá:
#   1. Ajuste pela GUI
#   2. Rode scripts/sync-xfce.sh (copia os XMLs vivos para ./xfce/)
#   3. Revise o diff (git diff) e commite
{ pkgs, lib, ... }:
let
  # Canais do xfconf sincronizados da máquina viva.
  channels = [
    "displays"
    "keyboards"
    "thunar"
    "xfce4-appfinder"
    "xfce4-desktop"
    "xfce4-keyboard-shortcuts"
    "xfce4-notifyd"
    "xfce4-panel"
    "xfce4-screensaver"
    "xfce4-settings-editor"
    "xfce4-settings-manager"
    "xfce4-taskmanager"
    "xfce4-terminal"
    "xfwm4"
    "xsettings"
  ];
in
{
  # Tema de ícones Papirus (variante escura, via Net/IconThemeName em
  # ./xfce/xsettings.xml). Pastas coloridas: troque por
  # pkgs.papirus-icon-theme.override { color = "violet"; }.
  # O wmctrl é usado pelo ./xfce/xfce-wezterm.sh (keybind Super+Return).
  home.packages = [
    pkgs.papirus-icon-theme
    pkgs.wmctrl
  ];

  home.file = {
    # Pasta onde o Print salva os screenshots (bind em
    # ./xfce/xfce4-keyboard-shortcuts.xml).
    "Pictures/snip/.keep".text = "";

    # Terminal padrão do XFCE: Super+t, "Open Terminal Here" do Thunar
    # etc. O exo lê este arquivo (formato key=value, sem header).
    # O wezterm está nos systemPackages do host daily
    # (modules/nixos/desktop.nix) para o exo sempre achá-lo no PATH.
    ".config/xfce4/helpers.rc".text = ''
      TerminalEmulator=wezterm
    '';

    # Wallpaper gerenciado (o xfce4-desktop.xml aponta para cá — assim o
    # caminho não depende de hash do /nix/store nem de pacote instalado).
    ".config/xfce4/backgrounds/xfce-blue.jpg".source = ./xfce/backgrounds/xfce-blue.jpg;

    # Launchers do painel (plugin launcher-2 = WezTerm, launcher-7 =
    # Firefox). Sem eles, os ícones do painel não funcionam em instalação
    # nova.
    ".config/xfce4/panel/launcher-2/17885263881.desktop".source =
      ./xfce/panel/launcher-2/17885263881.desktop;
    ".config/xfce4/panel/launcher-7/17885264493.desktop".source =
      ./xfce/panel/launcher-7/17885264493.desktop;

    # Keybind Super+Return: abre/foca o wezterm (ver ./xfce/xfce-wezterm.sh).
    ".local/bin/xfce-wezterm.sh".source = ./xfce/xfce-wezterm.sh;
  }
  // builtins.listToAttrs (
    map (c: {
      name = ".config/xfce4/xfconf/xfce-perchannel-xml/${c}.xml";
      value.source = ./xfce + "/${c}.xml";
    }) channels
  );
}
