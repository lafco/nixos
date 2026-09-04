.files: [lafco/config](https://github.com/lafco/config).

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

```sh
# Instalação nova pela ISO minimal (TUI — escolhe host/disco/usuário):
sh <(curl -L https://raw.githubusercontent.com/lafco/nixos/main/install/install-iso.sh) # [docs/install.md]

# Servidor (deploy a partir da sua máquina):
./scripts/deploy-server.sh <ip-do-servidor>

# Máquina pessoal (rebuild local):
sudo nixos-rebuild switch --flake .#daily
```

Ainda manual:

- [ ] Identidade git da empresa em `home/profiles/work.nix` (nome/email do trabalho)
- [ ] Configurar chaves em `.sops.yaml` e criar `secrets/secrets.yaml`
