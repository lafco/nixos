# Organização do repo

## Onde cada coisa mora

| Caminho | O que é |
|---|---|
| `flake.nix` | Entrada única. Declara inputs (nixpkgs, home-manager, sops-nix, disko, treefmt) e os três alvos: `nixosConfigurations.daily`, `nixosConfigurations.server`, `homeConfigurations."lafco@work"`. |
| `hosts/<maquina>/default.nix` | Config específica da máquina NixOS (hostname, usuário, bootloader, segredos). Importa o `hardware-configuration.nix` e o `disko-config.nix` da mesma pasta. |
| `hosts/<maquina>/hardware-configuration.nix` | GERADO por máquina (drives/rede/firmware). Substitua o stub pelo arquivo real — o instalador da ISO faz isso por você. |
| `hosts/<maquina>/disko-config.nix` | Layout de disco declarativo (usado pelo disko-install na instalação). |
| `hosts/<maquina>/local.nix` | Opcional, por máquina, **no .gitignore**: overrides locais (hostname, disco, senha hasheada) gerados por `install/install-iso.sh`. Fica visível ao flake via `git add -N -f` (intent-to-add), sem nunca ser commitado. |
| `install/install-iso.sh` | Instalador TUI para a ISO minimal (habilita flakes, clona o repo, pergunta host/disco/usuário, gera hardware-config, chama o disko-install). Veja `docs/install.md`. |
| `modules/nixos/` | Módulos NixOS reutilizáveis: `common.nix` (tudo que é igual em daily e server), `desktop.nix` (XFCE, só daily), `server.nix` (endurecimento SSH, só server). |
| `lib/` | Helpers (`default.nix`) e `overlays.nix`: `pkgs.unstable.*` (pi/herdr) + shim `nodePackages.intelephense` (o `nodePackages` foi removido do nixpkgs em 2026; remove o shim quando o repo de dotfiles atualizar). |
| `home/lafco/` | Core do usuário em home-manager. Importa os módulos do repo de dotfiles ([lafco/config](https://github.com/lafco/config), input `dotfiles` do flake): `dotfiles.nix` (symlinks), `shell.nix`, `git.nix`, `editor.nix`, `terminal.nix` — mais o `ssh.nix` local. |
| `home/profiles/` | Deltas por máquina: `personal.nix` (daily: + apps/ai do repo de dotfiles), `work.nix` (empresa: identidade git do trabalho), `server.nix` (servidor: vazio). Importados DEPOIS do core, então sobrescrevem opções. |
| `secrets/` | `secrets.yaml` encriptado (sops-nix) — commitável; `.example` é só documentação. |
| `scripts/` | Atalhos: deploy do servidor e ativação na máquina da empresa. |
| `docs/` | Esta documentação, decisões e bootstrap. |

## Como a separação funciona

```
                 home/lafco (core: shell, git, nvim, tmux, direnv, packages)
                        │
      ┌─────────────────┼──────────────────┐
      │                 │                  │
 daily (NixOS)     work (standalone)   server (NixOS)
 + profiles/       + profiles/         + profiles/
   personal.nix      work.nix            server.nix
```

- **daily** e **server**: home-manager roda como módulo do NixOS
  (`home-manager.users.lafco = { imports = [ core perfil ]; }` no host).
- **work**: home-manager standalone (`homeConfigurations."lafco@work"` no
  flake) — funciona em qualquer Linux com Nix instalado, sem tocar no SO da
  empresa além do `/nix` + profile do usuário.
- O mesmo core vale para os três; cada perfil só ajusta o que difere
  (ex.: identidade git do trabalho em `work.nix`).

## Receitas

### Adicionar um programa do usuário

1. Crie `home/lafco/<programa>.nix` (ex.: `programs.gh.enable = true;`).
2. Importe em `home/lafco/default.nix`.
3. `nix fmt` e rebuild da máquina.

Se o programa é só da empresa → coloque em `home/profiles/work.nix`.

### Adicionar uma máquina NixOS

1. `cp -r hosts/daily hosts/<nova>` e ajuste.
2. Crie o módulo em `modules/nixos/` se houver algo reutilizável.
3. Registre em `flake.nix` (`nixosConfigurations.<nova> = ...`) com os módulos
   que ela usa.
4. Gere o `hardware-configuration.nix` na máquina real.

### Adicionar um programa de sistema

- Comum a tudo → `modules/nixos/common.nix`.
- Só desktop → `modules/nixos/desktop.nix`.
- Só servidor → `modules/nixos/server.nix`.
- Só uma máquina → direto no `hosts/<maquina>/default.nix`.

### Atualizar versões (input pinning)

```sh
nix flake update          # atualiza todos os inputs e o flake.lock
nix flake update nixpkgs  # só o nixpkgs
```

Commit sempre o `flake.lock`.

## Regras de ouro

1. **Nada de estado manual**: se você fez algo à mão e quer manter, vira módulo.
2. **Core é portátil**: `home/lafco/` deve funcionar nas três máquinas; o que
   for específico vai para `profiles/` ou `modules/nixos/`.
3. **Segredos nunca em texto claro**: só dentro do `secrets/secrets.yaml`
   encriptado (e nunca chaves privadas no repo).
4. **`stateVersion` é por máquina e imutável** depois da primeira instalação.
5. **Gere, não edite**: `hardware-configuration.nix` vem de ferramenta; se
   editá-lo, faça em um módulo separado para não perder mudanças.
