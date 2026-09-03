# Bootstrap — instalar tudo do zero

Ordem sugerida: comece pela máquina da empresa (menor risco), depois daily,
depois o servidor.

## 0. Preparação única (chaves)

```sh
# 1. Chave SSH (para o servidor e GitHub)
ssh-keygen -t ed25519 -C "lafco@<maquina>" -f ~/.ssh/id_ed25519

# 2. Chave age (segredos; usada para EDITAR e para o standalone no trabalho)
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
# copie a chave pública (age1...) para .sops.yaml no lugar de &lafco
```

## 1. Máquina da empresa (Ubuntu/Debian, home-manager standalone)

```sh
# 1. Instalar Nix (multi-user; pede sudo). Alternativas: Lix/Determinate — docs/decisions.md.
sh <(curl -L https://nixos.org/nix/install) --daemon

# 2. Clonar os DOIS repos:
#    - dotfiles (o home/modules/dotfiles.nix symlinka ~/dotfiles — obrigatório)
#    - este repo (nixos), em qualquer lugar (ex.: ~/nixos)
git clone https://github.com/lafco/config ~/dotfiles
git clone https://github.com/lafco/nixos ~/nixos

# 3. Ativar os dotfiles
cd ~/nixos && ./scripts/install-work.sh   # = home-manager switch --flake .#lafco@work
```

- Atualizar depois: `cd ~/nixos && git pull && home-manager switch --flake .#lafco@work`
  (ou `nix flake update` antes, se quiser bump de versões).
- Os dotfiles em `~/dotfiles` têm efeito imediato (symlinks) — edite lá sem
  rebuild; só packages/opções novas exigem `switch`.
- Rollback: `home-manager generations` e ativar uma anterior.
- Em rede corporativa com proxy: o daemon não herda o proxy do shell — configure
  `proxy`/`netrc-file` em `/etc/nix/nix.conf` (issue conhecido:
  [nix-installer#974](https://github.com/DeterminateSystems/nix-installer/issues/974)).
- Desinstalar: remover as gerações do profile e desinstalar o Nix
  (`/nix/nix-installer uninstall` se usou o installer da Determinate/Lix).
- Todo o estado fica em `/nix/store` + seu profile + `~/.config/home-manager`:
  o repo é a única fonte de verdade.

## 2. Máquina pessoal (daily — NixOS + XFCE)

### Opção A — nixos-anywhere (recomendada, instala tudo por SSH)

```sh
# Boot a máquina alvo com a ISO do NixOS 26.05 (ou qualquer live Linux com SSH)
# e com sua chave SSH autorizada, então:
nix run nixpkgs#nixos-anywhere -- \
  --flake .#daily \
  --generate-hardware-config nixos-facter ./hosts/daily/hardware-configuration.nix \
  root@<ip-da-maquina>
```

O nixos-anywhere roda o `disko-config.nix` (particiona), instala e gera o
hardware-configuration. Depois: commit o arquivo gerado e rebuilds normais.

### Opção B — instalação manual (ISO)

1. Boot da ISO, `nixos-generate-config`, copiar o resultado para
   `hosts/daily/hardware-configuration.nix`.
2. Rodar o layout manualmente: `nix run nixpkgs#disko -- --mode disko --flake .#daily`
   (formata o disco declarado em `disko-config.nix`).
3. `nixos-install --flake .#daily --no-root-passwd` e reboot.

### Pós-instalação

```sh
sudo nixos-rebuild switch --flake .#daily   # aplicar mudanças
sudo passwd lafco                           # trocar o "changeme"
# primeiro login já tem zsh + todo o ambiente do home-manager
```

- Segredos: a daily decripta com a chave SSH do host. Rode nela
  `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`, ponha o resultado em
  `.sops.yaml` (`&daily_host`) e re-encripte: `sops updatekeys secrets/secrets.yaml`.
- Não existem segredos obrigatórios no boot: você pode instalar tudo primeiro e
  configurar secrets depois (o serviço sops-nix só falha até o arquivo existir).

## 3. Servidor (headless, SSH-only)

### Primeira instalação (VPS)

```sh
# VPS já acessível por SSH com senha/chave do provedor:
nix run nixpkgs#nixos-anywhere -- \
  --flake .#server \
  --generate-hardware-config nixos-facter ./hosts/server/hardware-configuration.nix \
  root@<ip-do-vps>
```

- Ajuste antes: `device` do disco em `hosts/server/disko-config.nix`
  (`/dev/vda` em KVM, `/dev/sda` em bare metal) e sua chave pública em
  `hosts/server/default.nix`.
- VPS sem kexec (raro): alternativa é o `nixos-infect` a partir de uma imagem
  Ubuntu/Debian ([projeto](https://github.com/elitak/nixos-infect)) — manutenção
  incerta, prefira nixos-anywhere.
- Provedor sem suporte: instale por ISO/nixos-anywhere local como na daily.

### Atualizar depois

```sh
./scripts/deploy-server.sh <ip-do-vps>
# = nixos-rebuild switch --flake .#server --target-host root@<ip> --use-remote-sudo
```

### Segredos no servidor

O servidor decripta com a chave SSH do host: rode nele
`ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`, ponha o resultado em
`.sops.yaml` (`&server_host`) e rode `sops updatekeys secrets/secrets.yaml`.

### Notas

- Firewall ativo por padrão; o openssh já abre a porta 22 sozinho.
- `system.autoUpgrade` está comentado em `modules/nixos/server.nix` — descomente
  se quiser atualização automática.
- Tailscale opcional comentado no mesmo arquivo.

## 4. Segredos no dia a dia

```sh
nix develop              # entra no devShell com sops/age/ssh-to-age
sops secrets/secrets.yaml   # edita
# cada segredo vira arquivo em /run/secrets/<nome> (NixOS) ou
# ~/.config/sops-nix/<nome> (home-manager standalone)
```

O arquivo `secrets/secrets.yaml` encriptado DEVE ser commitado no git —
é assim que ele chega às máquinas. O que nunca entra no repo: as chaves
privadas (age/SSH).
