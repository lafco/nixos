# dotfiles — NixOS + home-manager

Configuração declarativa de tudo o que eu uso, em um único repo:

| Alvo | Sistema | Como é configurado |
|---|---|---|
| **daily** — máquina de uso diário | NixOS + XFCE | `nixosConfigurations.daily` (home-manager em modo módulo) |
| **server** — servidor SSH mínimo p/ dev | NixOS headless | `nixosConfigurations.server` (home-manager em modo módulo) |
| **work** — máquina da empresa | Ubuntu/Debian (SO da empresa) | `homeConfigurations."lafco@work"` (home-manager standalone) |

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
│   ├── lafco/                #   core compartilhado (shell, git, nvim, tmux…)
│   └── profiles/             #   personal / work / server
├── modules/nixos/            # módulos NixOS reutilizáveis (common, desktop, server)
├── secrets/                  # secrets.yaml encriptado (sops-nix)
├── scripts/                  # deploy do servidor e ativação na máquina da empresa
└── docs/                     # decisões, bootstrap e organização
```

Explicação detalhada: [`docs/structure.md`](docs/structure.md).

## Início rápido

```sh
# Máquina da empresa (Ubuntu/Debian):
#   1) instalar Nix  2) ./scripts/install-work.sh

# Servidor (deploy a partir da sua máquina):
./scripts/deploy-server.sh <ip-do-servidor>

# Máquina pessoal (rebuild local):
sudo nixos-rebuild switch --flake .#daily
```

Passo a passo completo (chaves SSH/age, segredos, instalação do zero):
[`docs/bootstrap.md`](docs/bootstrap.md).

## TODO antes do primeiro uso real

- [ ] Trocar identidade git em `home/lafco/git.nix` e `home/profiles/work.nix`
- [ ] Gerar `hosts/*/hardware-configuration.nix` nas máquinas reais
- [ ] Configurar chaves em `.sops.yaml` e criar `secrets/secrets.yaml`
- [ ] Colar sua chave SSH pública em `hosts/server/default.nix`
- [ ] Ajustar discos em `hosts/*/disko-config.nix`
