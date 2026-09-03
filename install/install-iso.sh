#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# Instalador TUI do NixOS a partir da ISO minimal.
#
# Fluxo: boot da ISO minimal → roda este script → TUI (host, disco, usuário,
# senha) → hardware-config gerado → local.nix com overrides da máquina →
# disko-install formata, monta e instala → reboot.
#
# Como obter o script na ISO (qualquer uma):
#   A) Repo no GitHub/GitLab:
#        sh <(curl -L https://raw.githubusercontent.com/USER/dotfiles/main/install/install-iso.sh)
#   B) Repo servido na rede local (nesta máquina):
#        cd <repo> && git update-server-info && python3 -m http.server 8000
#        # na ISO:
#        sh <(curl -L http://IP:8000/install/install-iso.sh)
#   C) Repo num pendrive: rode o script direto do pendrive
#        sh /media/pendrive/install/install-iso.sh   (detecta o repo ao lado)
#
# Detalhes: docs/install.md
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

say() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
die() {
  printf '\n\033[1;31mERRO: %s\033[0m\n' "$*" >&2
  exit 1
}

# ── 0. pré-checagens ──────────────────────────────────────────────────────
[ "$(id -u)" -eq 0 ] && die "rode como o usuário 'nixos' da ISO (não como root) — o script usa sudo."
sudo -v || die "sudo indisponível (a ISO minimal tem sudo sem senha para o usuário nixos)."

# ── 1. habilita flakes (usuário + root) — o que a ISO sempre pede ─────────
say "Habilitando flakes (nix-command + flakes)"
mkdir -p ~/.config/nix
grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null \
  || echo "experimental-features = nix-command flakes" >>~/.config/nix/nix.conf
# sudo não herda a config do usuário; escreve também a do root (/etc/nix).
sudo sh -c 'mkdir -p /etc/nix; grep -q experimental-features /etc/nix/nix.conf 2>/dev/null \
  || echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf'

# ── 2. ferramentas da TUI ─────────────────────────────────────────────────
say "Baixando git e gum (interface da TUI)"
if ! command -v git >/dev/null 2>&1 || ! command -v gum >/dev/null 2>&1; then
  nix profile install nixpkgs#git nixpkgs#gum
fi

# ── 3. obtém o repo ───────────────────────────────────────────────────────
say "Localizando o repo de configuração"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -f "$SCRIPT_DIR/../flake.nix" ]; then
  REPO_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
  echo "Repo encontrado ao lado do script (modo USB/local): $REPO_DIR"
else
  url="${REPO_URL:-}"
  [ -z "$url" ] && url=$(gum input --placeholder "URL do repo para git clone (ex.: https://github.com/voce/dotfiles) — Enter cancela")
  [ -z "$url" ] && die "sem repo. Veja as opções A/B/C no cabeçalho deste script."
  REPO_DIR="$HOME/dotfiles"
  git clone "$url" "$REPO_DIR"
fi
cd "$REPO_DIR"

# ── 4. TUI ────────────────────────────────────────────────────────────────
gum style --foreground 212 --bold --border double --padding "1 4" \
  "Instalador NixOS" "repo: $(basename "$REPO_DIR")"

HOST=$(gum choose "daily" "server" --header "Qual máquina você está instalando?")

# boot mode: daily espera UEFI (systemd-boot), server espera BIOS (GRUB)
if [ -d /sys/firmware/efi ]; then
  BOOTMODE=uefi
else
  BOOTMODE=bios
fi
if [ "$HOST" = "daily" ] && [ "$BOOTMODE" != "uefi" ]; then
  die "host 'daily' usa systemd-boot (UEFI), mas a máquina bootou em BIOS. Boote a ISO em modo UEFI ou ajuste hosts/daily/disko-config.nix."
fi
if [ "$HOST" = "server" ] && [ "$BOOTMODE" != "bios" ]; then
  die "host 'server' usa GRUB/BIOS, mas a máquina bootou em UEFI. Ajuste hosts/server/disko-config.nix (ESP) ou instale o servidor remotamente com nixos-anywhere (docs/install.md)."
fi

HOSTNAME=$(gum input --value "$HOST" --placeholder "hostname da máquina")
mapfile -t disk_opts < <(lsblk -dno NAME,SIZE,MODEL | awk '{print "/dev/" $1 "  (" $2 " " $3 ")"}')
[ "${#disk_opts[@]}" -gt 0 ] || die "nenhum disco encontrado."
DISK=$(gum choose "${disk_opts[@]}" --header "Em qual disco instalar? (será FORMATADO)")
DISK=${DISK%% *}
# prefere um caminho estável by-id (não muda se a ordem dos discos mudar)
DISK_BY_ID=$DISK
for link in /dev/disk/by-id/*; do
  [ -e "$link" ] || continue
  case "$link" in *-part*) continue ;; esac
  if [ "$(readlink -f "$link")" = "$DISK" ]; then
    DISK_BY_ID=$link
    break
  fi
done
USERNAME=$(gum input --value "lafco" --placeholder "nome de usuário")
PASS1=$(gum input --password --placeholder "senha do usuário")
PASS2=$(gum input --password --placeholder "repita a senha")
[ "$PASS1" = "$PASS2" ] || die "as senhas não conferem."
TZ=$(gum input --value "America/Sao_Paulo" --placeholder "timezone (ex.: America/Sao_Paulo)")
SSHPUB=""
if [ "$HOST" = "server" ]; then
  SSHPUB=$(gum input --placeholder "chave SSH pública para login no servidor (Enter p/ pular)")
fi
AGEKEY=$(gum input --placeholder "caminho de uma chave age (keys.txt) para copiar ao sistema — Enter p/ pular")

gum style --border normal --padding "1 2" \
  "host:      $HOST  ($BOOTMODE)" \
  "hostname:  $HOSTNAME" \
  "disco:     $DISK_BY_ID  ⚠️ será formatado" \
  "usuário:   $USERNAME" \
  "timezone:  $TZ"
gum confirm "Confirma e instala?" || die "cancelado."

# ── 5. hardware-configuration.nix (sem filesystems: o disko é dono deles) ─
say "Gerando hardware-configuration.nix"
sudo nixos-generate-config --show-hardware-config --no-filesystems \
  >"hosts/$HOST/hardware-configuration.nix"

# ── 6. local.nix: overrides DESTA máquina. Está no .gitignore; o
#      `git add -N -f` (intent-to-add, padrão do nixos-anywhere) torna o
#      conteúdo visível ao flake sem deixá-lo staged para commit ───────────
say "Gerando hosts/$HOST/local.nix"
HASH=$(nix shell nixpkgs#mkpasswd --command mkpasswd -m sha-512 "$PASS1")
{
  echo "# Gerado por install/install-iso.sh — específico DESTA máquina."
  echo "# Está no .gitignore; o intent-to-add o mantém visível ao flake."
  echo "{ lib, ... }:"
  echo "{"
  echo "  networking.hostName = lib.mkForce \"$HOSTNAME\";"
  echo "  time.timeZone = lib.mkForce \"$TZ\";"
  echo "  users.users.$USERNAME.initialHashedPassword = lib.mkForce \"$HASH\";"
  echo "  users.users.$USERNAME.initialPassword = lib.mkForce null;"
  echo "  disko.devices.disk.main.device = lib.mkForce \"$DISK_BY_ID\";"
  if [ -n "$SSHPUB" ]; then
    echo "  users.users.$USERNAME.openssh.authorizedKeys.keys = lib.mkForce [ \"${SSHPUB//\"/\\\"}\" ];"
  fi
  echo "}"
} >"hosts/$HOST/local.nix"
git add -N -f "hosts/$HOST/local.nix"

# ── 7. instalação (formata com disko, monta e roda nixos-install) ─────────
say "Instalando (disko-install — pode demorar)"
INSTALL_ARGS=(--flake ".#$HOST" --disk main "$DISK_BY_ID" --extra-files "$REPO_DIR" "home/$USERNAME/dotfiles")
[ "$HOST" = "daily" ] && INSTALL_ARGS+=(--write-efi-boot-entries)
if [ -n "$AGEKEY" ] && [ -f "$AGEKEY" ]; then
  INSTALL_ARGS+=(--extra-files "$AGEKEY" "home/$USERNAME/.config/sops/age/keys.txt")
fi
sudo nix run 'github:nix-community/disko/latest#disko-install' -- "${INSTALL_ARGS[@]}"

# ── 8. finalização ────────────────────────────────────────────────────────
gum style --foreground 212 --bold \
  "Instalação concluída! ✓" \
  "" \
  "Após o primeiro boot, ajuste as permissões do repo copiado:" \
  "  cd ~/dotfiles && git reset && sudo chown -R $USERNAME: ~/dotfiles" \
  "" \
  "Para aplicar mudanças depois: sudo nixos-rebuild switch --flake ~/dotfiles#$HOST"
gum confirm "Reiniciar agora?" && sudo reboot
