# Instalando a partir da ISO minimal (TUI)

O objetivo: baixar a **ISO minimal do NixOS**, bootar, rodar UM comando e
responder as perguntas na TUI — o resto (flakes, clone do repo,
hardware-configuration, particionamento e instalação) é automático.

## 1. Disponibilizar o repo (escolha uma)

A ISO precisa alcançar este repo de alguma forma:

- **A. GitHub (recomendado):** suba o repo (`git push`) e use a URL
  pública. É a opção mais simples de manter.

O script clona **`https://github.com/lafco/nixos` por padrão** (sem
perguntar a URL) para **`~/nixos`**; se o repo estiver em outro lugar
(mirror corporativo, clone local), sobrescreva na hora de rodar:

```sh
REPO_URL=https://seu-mirror/lafco/nixos sh <(curl -L <URL-do-script>/install/install-iso.sh)
```
- **B. Rede local:** na máquina com o repo:
  ```sh
  cd ~/nixos && git update-server-info && python3 -m http.server 8000
  ```
  (serve o repo por HTTP "dumb"; funciona para `git clone` e `curl`.)
- **C. Pendrive:** copie o repo inteiro para um pendrive e rode o script
  direto dele na ISO.

### 1.1. A URL curta decorável (`lafco.github.io/i`)

Para não decorar a URL gigante do raw do GitHub, decore só esta:

```sh
curl -Ls https://lafco.github.io/i | sh
```

**Como funciona:** `/i` é um arquivo estático no GitHub Pages (repo
`lafco/lafco.github.io`) que só baixa e executa a versão **mais nova** do
`install/install-iso.sh` deste repo (branch `main`). Você nunca atualiza a
URL curta: toda mudança no instalador vale na hora, porque o bootstrap vive
em cima da `main`. Não é um serviço de redutor de terceiros — é só um
arquivo seu num domínio do GitHub (com `.nojekyll` para o Pages servir os
arquivos literalmente, sem processar).

**Configuração única:**

1. Crie o repo **vazio** `lafco.github.io` no GitHub (público, sem README).
2. Neste repo: `./scripts/publish-pages.sh` (copia `pages/` para lá e faz
   push). O Pages publica a branch `main` automaticamente.
3. Teste: `curl -Ls https://lafco.github.io/i | head` deve mostrar o
   bootstrap. (Se der 404 logo em seguida, o Pages ainda não publicou —
   espere ~1 minuto.)

**Manutenção:** o conteúdo publicado é o da pasta `pages/` (`i`,
`.nojekyll`, `index.html`). Rode `./scripts/publish-pages.sh` de novo se
mudar algo lá — o arquivo `i` em si nunca precisa mudar.

## 2. Baixar e bootar a ISO

1. Baixe a [ISO minimal do NixOS 26.05](https://nixos.org/download/#nixos-iso).
2. Grave num pendrive (ex.: `sudo dd if=nixos.iso of=/dev/sdX bs=4M status=progress`)
   ou use no Ventoy.
3. Boote **em modo UEFI** para instalar o host `daily` (BIOS serve apenas para
   o `server`, cujo layout usa GRUB/BIOS).

## 3. Rodar o instalador

Na ISO (login `nixos`, sem senha):

```sh
# recomendado — URL curta decorável (seção 1.1):
curl -Ls https://lafco.github.io/i | sh

# equivalente, direto do GitHub (opção A):
sh <(curl -L https://raw.githubusercontent.com/lafco/nixos/main/install/install-iso.sh)

# opção C (pendrive):
sh /media/<pendrive>/install/install-iso.sh

# se preferir clonar na mão antes:
git clone https://github.com/lafco/nixos ~/nixos && cd ~/nixos && ./install/install-iso.sh
```

A TUI pergunta: **host** (daily/server) → **hostname** → **disco** → **usuário**
→ **senha** → **timezone** (→ chave SSH pública, no caso do server → caminho
opcional de uma chave age para já deixar o sops-nix pronto).

O script então:

1. garante `nix-command flakes` para o usuário e passa as features para os
   comandos do root via `NIX_CONFIG` (`sudo env`) — o `/etc/nix` da ISO é
   **somente leitura**, então o script não o altera;
2. instala `git` + `gum` via nix;
3. gera `hosts/<host>/hardware-configuration.nix`
   (`nixos-generate-config --show-hardware-config --no-filesystems` — sem
   filesystems porque o **disko é dono deles**);
4. escreve `hosts/<host>/local.nix` com os overrides da máquina (hostname,
   timezone, senha **hasheada**, disco em `/dev/disk/by-id/...`, chave SSH) e
   usa `git add -N -f` (intent-to-add) para o flake enxergá-lo sem o deixar
   staged — o arquivo fica no `.gitignore`;
5. clona o repo de dotfiles (`github:lafco/config`) e instala em duas etapas
   — de propósito, para não estourar a RAM:
   1. `disko --mode format,mount --flake .#<host>`: formata o disco escolhido
      e monta tudo em `/mnt` (ativa também o swapfile de 8G do layout);
   2. `nixos-install --flake .#<host>`: o nixos-install do 26.05 roda
      `nix build --store /mnt`, ou seja, baixa/builda a closure **direto no
      store do SSD** — a closure nunca passa inteira pela RAM da ISO.
   Antes do install, os dois repos são copiados para dentro da máquina nova:
   **este repo → `~/nixos`** e **dotfiles → `~/dotfiles`** (o
   `home/modules/dotfiles.nix` symlinka os dotfiles de lá — single source
   of truth).

> ⚠️ O disco escolhido é **formatado por completo** — sem dual-boot.

## 4. Pós-instalação (primeiro boot)

```sh
cd ~/nixos
git reset                        # remove os intent-to-add do install
sudo chown -R lafco: ~/nixos ~/dotfiles   # os repos foram copiados como root
sudo passwd lafco                # opcional: trocar a senha (ela não será sobrescrita)
```

Recomendado: **commitar o `hardware-configuration.nix`** gerado (é específico
da máquina e versionado de propósito):

```sh
cd ~/nixos && git add hosts/<host>/hardware-configuration.nix && git commit -m "hardware: <host>"
```

O `local.nix` continua ignorado — as escolhas locais não entram no repo
compartilhado (e `git add -A` nunca o incluirá).

Os dois repos têm papéis distintos:

- **`~/nixos`** (este repo): sistema + home-manager. Aplicar mudanças:
  `sudo nixos-rebuild switch --flake ~/nixos#daily`.
- **`~/dotfiles`** (`github:lafco/config`): os dotfiles em si (bash, nvim,
  wezterm, zellij, starship…). **Editar aqui tem efeito imediato** (sem
  rebuild) — o home-manager cria symlinks para `~/dotfiles`.

## 5. Alternativa: instalação remota (nixos-anywhere)

Se a máquina alvo estiver acessível por SSH (ex.: o servidor VPS), em vez de
bootar a ISO nela você pode instalar a partir de qualquer máquina com Nix:

```sh
nix run nixpkgs#nixos-anywhere -- \
  --flake .#server \
  --generate-hardware-config nixos-generate-config ./hosts/server/hardware-configuration.nix \
  root@<ip-do-vps>
```

(Esse fluxo é o recomendado para o VPS: não precisa de ISO nem de BIOS/UEFI.)

## 6. Solução de problemas

| Sintoma | Causa/correção |
|---|---|
| `sudo nix ...` reclama de features experimentais | o script usa `sudo env NIX_CONFIG=...` (o `/etc/nix` da ISO é read-only); à mão, use `sudo nix --extra-experimental-features 'nix-command flakes' ...`. |
| `sh: /etc/nix/nix.conf: read-only file system` | esperado na ISO (squashfs) — era um bug de versões antigas do script que tentavam escrever lá; rode a versão atual, que usa `NIX_CONFIG`. |
| `hosts/<host>/hardware-configuration.nix: No such file or directory` | o clone usado não é este repo — provavelmente o de dotfiles (`lafco/config`, que não tem `hosts/`) em `~/dotfiles`. O script agora clona em `~/nixos` e valida o `flake.nix`/`hosts/` antes de seguir; na dúvida, `rm -rf ~/dotfiles` (clone antigo na ISO) e rode de novo. |
| `Out of memory`/OOM-killer durante o install | na ISO os paths novos do store vão para tmpfs (RAM) e tentativas repetidas acumulam GB no mesmo boot. **Reinicie a ISO** e rode o script uma única vez. O instalador atual não usa mais `disko-install` (que buildava a closure inteira em RAM antes de copiar para o disco): ele formata/monta com `disko` e o `nixos-install` builda **direto no store do SSD** (`nix build --store /mnt`), com o swapfile do disko ativo. Se ainda assim faltar RAM para a avaliação, instale via `nixos-anywhere` (seção 5). |
| warning `no-write-lock-file` durante o install | vem de ferramentas disko/nixos-install upstream (fixam `--option no-write-lock-file true`); é inofensivo. |
| `git: command not found` | a ISO minimal não traz git; o script instala via `nix profile add nixpkgs#git`. |
| "host 'daily' ... BIOS" | boote a ISO em UEFI (ou ajuste o disko para GRUB). |
| "host 'server' ... UEFI" | use o fluxo remoto (nixos-anywhere) ou adicione ESP no disko do server. |
| Clone falha na rede corporativa | na ISO o `/etc/nix` é read-only: use `NIX_CONFIG` (ou `~/.config/nix/nix.conf`) para o proxy do Nix e `git config http.proxy`. |
| Esqueceu a senha | boot da ISO de novo → `disko-install --mode mount --flake .#host --disk main <by-id>` monta sem formatar; ou use `nixos-enter` e `passwd`. |
