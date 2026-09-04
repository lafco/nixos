# dotfiles — NixOS + home-manager

Configuração declarativa de tudo o que eu uso, em um único repo:

| Alvo | Sistema | Como é configurado |
|---|---|---|
| **daily** — máquina de uso diário | NixOS + XFCE | `nixosConfigurations.daily` (home-manager em modo módulo) |
| **server** — servidor SSH mínimo p/ dev | NixOS headless | `nixosConfigurations.server` (home-manager em modo módulo) |
| **work** — máquina da empresa | Ubuntu/Debian (SO da empresa) | `homeConfigurations."lafco@work"` (home-manager standalone) |

**Dotfiles**: os arquivos do usuário (bash, nvim, wezterm, zellij, starship…)
vivem no repo [lafco/config](https://github.com/lafco/config), clonado em
`~/dotfiles`. Os módulos home-manager que os consomem moram AQUI em
`home/modules/` (o repo de dotfiles virou só stow + CLI `dot`), e o
`home/modules/dotfiles.nix` cria os symlinks — **editar em `~/dotfiles` tem
efeito imediato**, sem rebuild.

## Decisão principal (resumo)

- **Implementação:** Nix oficial (CppNix 2.34 / NixOS 26.05) — mais estável e documentado.
- **Fork alternativo:** [Lix](https://lix.systems/) é drop-in e já vem preparado (comentado) no flake.
- **Determinate:** só vale a pena se um dia a máquina do trabalho for macOS ou com monorepo grande.
- Comparação completa com fontes: [`docs/decisions.md`](docs/decisions.md).

## Estrutura

```
├── flake.nix                 # entrada do repo: inputs + máquinas
├── treefmt.nix               # `nix fmt` (nixfmt + shfmt)
├── .sops.yaml                # chaves dos segredos (sops-nix/age)
├── hosts/                    # máquinas NixOS
│   ├── daily/                #   desktop XFCE
│   └── server/               #   servidor headless
├── home/                     # configuração do usuário (home-manager)
│   ├── lafco/                #   core do usuário (importa home/modules/)
│   ├── modules/              #   módulos HM: dotfiles (symlinks), shell, git,
│   │                         #   editor, terminal, dev (runtimes), ai, apps,
│   │                         #   xfce (painel/keybinds)
│   └── profiles/             #   personal / work / server
├── modules/nixos/            # módulos NixOS reutilizáveis (common, desktop, gaming, torrents, database, server)
├── install/                  # instalador TUI da ISO minimal (install-iso.sh)
├── secrets/                  # secrets.yaml encriptado (sops-nix)
├── scripts/                  # deploy do servidor e ativação na máquina da empresa
└── docs/                     # decisões, bootstrap, instalação e organização
```

Explicação detalhada: [`docs/structure.md`](docs/structure.md).

## Início rápido

```sh
# Instalação nova pela ISO minimal (TUI — escolhe host/disco/usuário):
sh <(curl -L <url>/install/install-iso.sh)   # veja docs/install.md

# Máquina da empresa (Ubuntu/Debian):
#   1) instalar Nix  2) ./scripts/install-work.sh

# Servidor (deploy a partir da sua máquina):
./scripts/deploy-server.sh <ip-do-servidor>

# Máquina pessoal (rebuild local):
sudo nixos-rebuild switch --flake .#daily
```

Passo a passo completo (chaves SSH/age, segredos, instalação do zero):
[`docs/bootstrap.md`](docs/bootstrap.md) e [`docs/install.md`](docs/install.md).

## TODO antes do primeiro uso real

Já coberto pelo `install/install-iso.sh` (a TUI pergunta/gera na hora):

- [x] Gerar `hosts/*/hardware-configuration.nix` (o script roda `nixos-generate-config`)
- [x] Ajustar o disco em `hosts/*/disko-config.nix` (o script sobrescreve `device` no `local.nix`)
- [x] Chave SSH do servidor (o script pergunta e grava no `local.nix` do host `server`)
- [x] Identidade git pessoal (`lafco <lafgo@proton.me>` em `home/modules/git.nix`)

Ainda manual:

- [ ] Identidade git da empresa em `home/profiles/work.nix` (nome/email do trabalho)
- [ ] Configurar chaves em `.sops.yaml` e criar `secrets/secrets.yaml`
