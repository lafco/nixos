# XFCE (só na daily): painel (barra de tarefas) e keybinds declarativos.
#
# Os arquivos XML são o formato do xfconf (o banco de configurações do XFCE);
# o home-manager os coloca em ~/.config/xfce4/xfconf/xfce-perchannel-xml/.
#
# ⚠️ Config declarativa: mudanças feitas pela GUI do XFCE são sobrescritas no
# próximo `switch` — edite os XML daqui (home/modules/xfce/) e rode o rebuild.
{ ... }:
{
  home.file = {
    ".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml".source =
      ./xfce/xfce4-panel.xml;
    ".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml".source =
      ./xfce/xfce4-keyboard-shortcuts.xml;

    # Terminal padrão do XFCE: Super+t (exo-open --launch TerminalEmulator),
    # "Open Terminal Here" do Thunar etc. O exo lê este arquivo
    # (formato key=value, grupo [Default] implícito — sem header).
    # O wezterm está nos systemPackages do host daily
    # (modules/nixos/desktop.nix) para o exo sempre achá-lo no PATH.
    ".config/xfce4/helpers.rc".text = ''
      TerminalEmulator=wezterm
    '';
  };
}
