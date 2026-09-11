# Decisões técnicas (com fontes)

Pesquisa feita em set/2026 para escolher o caminho deste repo.
Todas as decisões e alternativas estão aqui, com links.

## 1. Nix oficial vs Lix vs Determinate Systems

| | **Nix oficial (CppNix)** | **Lix** | **Determinate Nix** |
|---|---|---|---|
| Mantenedor | Time Nix / NixOS Foundation | Time voluntário (Lunaphied, pennae, raito…) | Determinate Systems, Inc. |
| Licença | LGPL-2.1 | LGPL-2.1-or-later | LGPL-2.1 (derivado do CppNix) |
| Versão (set/2026) | 2.34.x | 2.95.x | 3.x |
| Instalação | installer oficial / distro / ISO | `curl … install.lix.systems/lix` | `curl … install.determinate.systems/nix` |
| Compatibilidade | referência | drop-in (mesmo CLI `nix`, mesmo nixpkgs) | drop-in; compatível com NixOS |
| Diferenciais | mais estável e documentado | pipe operator, erros melhores, infra comunitária | eval paralelo, lazy trees, builder Linux no macOS, FlakeHub |
| Melhor caso | padrão geral | governança comunitária + ergonomia | macOS, monorepos, times |

Contexto de governança: em 2024 houve uma crise de liderança (influência da
Determinate, mantenedores saindo do nixpkgs — [LWN](https://lwn.net/Articles/970824/));
Eelco Dolstra deixou o board da [NixOS Foundation](https://lwn.net/Articles/973103/);
surgiram os forks **Lix** (avaliador) e **Aux** (coleção de pacotes); e em 2025 o
primeiro board [eleito pela comunidade](https://nixos.org/blog/announcements/2025/foundation-board-2025/)
tomou posse. A Determinate financia o Lix e vários fundadores do Lix são/foram
funcionários da Determinate, mas são projetos distintos: Determinate Nix é um
derivado corporativo do CppNix; Lix é um fork comunitário do avaliador.

### Decisão: Nix oficial (CppNix)

- Melhor custo-benefício para os três alvos deste repo (desktop Linux, dotfiles
  em Ubuntu/Debian e servidor headless): mais estável, mais documentado,
  maior cache e agora com governança comunitária.
- **Lix** é o plano B drop-in: basta descomentar o input `lix-module` no
  `flake.nix` e adicionar `lix-module.nixosModules.default` à lista de módulos
  de cada host. Instalador: `curl -sSf -L https://install.lix.systems/lix | sh -s -- install`
  ([lix.systems](https://lix.systems/install/)).
- **Determinate Nix** seria a escolha se a máquina do trabalho fosse macOS
  (builder Linux nativo, lazy trees) ou houvesse monorepo grande.
  Para uma pessoa só, o ecossistema puxa para FlakeHub (cache pago,
  URLs `flakehub.com/f/...`) sem ganho proporcional — evitei URLs do FlakeHub
  no repo de propósito, para manter portabilidade entre as três opções.
- LSP: **nixd** (avalia a config e completa opções) + **nil** (análise rápida),
  já no devShell do repo ([poll da comunidade](https://discourse.nixos.org/t/poll-nix-lsp-language-server-protocol/70658)).

Fontes: [Nix 2.34 release notes](https://releases.nixos.org/nix/nix-2.34.1/manual/release-notes/rl-2.34.html) ·
[NixOS 25.11](https://nixos.org/blog/announcements/2025/nixos-2511/) ·
[Lix 2.94](https://lix.systems/blog/2025-11-18-lix-2.94-release/) ·
[Lix team](https://lix.systems/team/) ·
[Determinate recap](https://determinate.systems/blog/determinate-nix-recap/) ·
[FlakeHub](https://determinate.systems/products/flakehub/).

## 2. Flakes e organização do repo

- **Flakes**: padrão de fato da comunidade ([survey 2025](https://discourse.nixos.org/t/2025-nixos-community-survey-report/78812));
  `flake.lock` versiona as entradas e é commitado.
- **flake-parts × outputs simples**: a comunidade está dividida
  ([threads](https://programming.dev/comment/14662492)). Escolhi **outputs
  simples** (estilo [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)):
  menos abstrações para aprender e depurar, e migrar para flake-parts depois é
  mecânico. O formato `hosts/ + home/ + modules/ + secrets/` é o consenso
  comunitário (mesma forma do template "standard" do Misterio77).
- **home-manager nos dois modos**: módulo no NixOS (daily/server) e standalone
  na máquina da empresa — o core em `home/lafco/` é compartilhado, cada máquina
  só adiciona um perfil ([manual](https://home-manager.dev/manual/unstable/nix-flakes.html)).
- **nixpkgs**: estável `nixos-26.05` em tudo; `nixpkgs-unstable` fica comentado
  no flake para pacotes pontuais.

## 3. Segredos: sops-nix (escolhido) × agenix

[sops-nix](https://github.com/Mic92/sops-nix) encripta um YAML com chaves
age/PGP, decripta na ativação e funciona tanto em NixOS quanto em home-manager
standalone — exatamente os dois modos deste repo. Suporte de primeira classe a
chaves SSH de host via `ssh-to-age` (é assim que daily/server decriptam).
[agenix](https://github.com/ryantm/agenix) é a alternativa mais enxuta.
Comparação completa: [NixOS Wiki](https://wiki.nixos.org/wiki/Comparison_of_secret_managing_schemes).

## 4. Instalação e deploy

- **Instalação do zero**: [disko](https://github.com/nix-community/disko) (layout
  declarativo, já nos hosts) + [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
  (instala por SSH em um comando e gera o `hardware-configuration.nix`).
- **Atualização do servidor**: `nixos-rebuild --target-host` (script
  `scripts/deploy-server.sh`) — para UM servidor não vale adotar
  [colmena](https://github.com/zhaofengli/colmena) (frota) nem
  [deploy-rs](https://github.com/serokell/deploy-rs) (rollbacks, pouco ativo).
  ([comparativo](https://discourse.nixos.org/t/best-nixos-deployment-tool-for-my-situation/71126))
- **Formatação**: [nixfmt](https://github.com/NixOS/nixfmt) via
  [treefmt-nix](https://github.com/numtide/treefmt-nix) → `nix fmt`.
- **Referências de estrutura**: [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs),
  [NotAShelf/nyx](https://github.com/NotAShelf/nyxexprs),
  [fufexan/dotfiles](https://github.com/fufexan/dotfiles),
  [Ryan Yin — NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/).

## 5. SecretSpec e devenv — avaliados em set/2026 e NÃO adotados (por enquanto)

### SecretSpec → esperar o 1.0 (sops-nix permanece)

[SecretSpec](https://secretspec.dev/) (Cachix, Apache-2.0) separa a *declaração* de
segredos (`secretspec.toml`, commitável) do *provisionamento* (provider por máquina:
keyring, 1Password, SOPS, age, systemd credentials…), resolvendo em runtime via
`secretspec run`. Avaliação (set/2026, v0.20.0):

- **Maturidade é o fator decisivo**: pré-1.0, 36 releases com ~18 breaking, minors
  quase semanais ([lib.rs](https://lib.rs/crates/secretspec)) — cada bump do nixpkgs
  arriscaria churn no flake.
- **Não tem módulo NixOS nem home-manager** (só pacote no nixpkgs + integração com
  devenv + provider systemd-credential): adotar significaria perder o
  `sops.secrets.<name>` automático e escrever `LoadCredential` na mão por serviço.
- **Escala**: profiles/scopes/SDKs/audit brilham para times; para 3 máquinas sem
  segredos reais, é overkill.
- **Sem lock-in na espera**: o [provider SOPS](https://secretspec.dev/providers/sops/)
  dele lê o mesmo `secrets/secrets.yaml` (age + ssh-to-age) que este repo já usa.

**Decisão**: manter sops-nix. **Reavaliar quando** sair o 1.0 (ou um módulo NixOS de
primeira classe). Piloto opcional de baixo custo: CLI no trabalho lendo o
`secrets.yaml` via provider SOPS, sem trocar o provisionamento real.
Acompanhar: [anúncio](https://discourse.nixos.org/t/announcing-secretspec-declarative-secrets-management/67021),
[0.17](https://discourse.nixos.org/t/secretspec-0-17-scopes-secrets-caching-sops-age-and-systemd-credentials/79184),
[0.20](https://discourse.nixos.org/t/secretspec-0-20/79863).

### devenv → não adotado (repo permanece flakes puros)

[devenv](https://devenv.sh/) (Cachix, Apache-2.0, v2.2 em set/2026) é um sistema de
módulos de alto nível (languages, services, processes, tasks, hooks) para ambientes
de dev. Avaliação:

- O próprio projeto recomenda o **CLI dedicado** (`devenv.nix` + `devenv.lock`); o
  modo via flake é explicitamente "reduced features" ([Using with Flakes](https://devenv.sh/guides/using-with-flakes/))
  — sem GC protection, sem caching de eval, sem integração SecretSpec — e exige
  `--no-pure-eval` + cache próprio (`devenv.cachix.org`).
- Para o **devShell deste repo** (nixfmt, sops, age, nil, nixos-anywhere), o
  `devShells.default` + nix-direnv já resolve: devenv seria uma abstração e um cache
  extras para ganho ~zero.
- O caso de uso real dele é **ambiente por projeto** (services como postgres/redis,
  toolchain pinada) — se um projeto futuro precisar, usar o CLI por projeto, fora
  deste repo de OS.
- Direção: migração em andamento para [Tvix](https://devenv.sh/blog/2024/10/22/devenv-is-switching-its-nix-implementation-to-tvix/).

**Decisão**: não adotar neste repo. **Reconsiderar** apenas como padrão por projeto
(na máquina da empresa/daily), nunca como substituto do devShell do repo.

## 6. Extensões do Firefox: overlay `firefox-addons` + bloqueio de YouTube Shorts

### Fonte das extensões: overlay rastreado pelo AMO (não hashes à mão)

Até set/2026 o `home/modules/apps.nix` fixava cada extensão com
`pkgs.fetchFirefoxAddon { url = "…/file/<id>/<slug>-<versão>.xpi"; sha256 = …; }`.
Isso amarra URL **e** hash ao arquivo do addons.mozilla.org, exige edição manual
a cada bump e ainda reescreve o `gecko.id` do manifesto para `nixos@<nome>`
(o que faz o Firefox usar um ID que não é o do AMO).

Alternativa adotada: o flake input
[`gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons`](https://gitlab.com/rycee/nur-expressions/-/tree/master/pkgs/firefox-addons)
— o mesmo overlay citado na documentação do home-manager. Ele expõe
`overlays.default`, aplicado em `lib/overlays.nix`, e mantém
`pkgs.firefox-addons.<nome>` com versão + hash no `flake.lock`
(atualização via `nix flake update firefox-addons`).

- O ID canônico vem do `passthru.addonId` do pacote (nesse overlay) ou do
  `passthru.extid` do `fetchFirefoxAddon` do nixpkgs — `apps.nix` aceita os
  dois via `... .extid or ... .addonId`. Assim o uBO passa a ser
  `uBlock0@raymondhill.net` (ID real do AMO) em vez de `nixos@ublock-origin`.
- O repositório `nix-community/nixpkgs-firefox-addons` **não existe** (404 na
  API do GitHub, verificado em set/2026) — não é o overlay do home-manager.
- As três extensões usadas aqui (uBlock Origin, Proton Pass, Pywalfox) estão no
  overlay, nas mesmas versões que estavam pinadas à mão.

### `fetchFirefoxAddon` era incompatível com `extensions.packages` (3 bugs)

A configuração anterior (2026-08) usava `pkgs.fetchFirefoxAddon` para as três
 extensões. Verificado em set/2026, isso produzia **três** problemas:

1. **Nenhuma extensão era instalada.** O `fetchFirefoxAddon` deixa o `.xpi` na
   raiz do pacote (`$out/nixos@<nome>.xpi`), mas o módulo do home-manager copia
   `<pkg>/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}` para
   `<perfil>/extensions`. O buildEnv resultante não tinha `share/`, então o
   home-manager criava um symlink **pendurado** e o Firefox carregava zero
   extensões (`extensions.json` só listava addons nativos).
2. **IDs falsos.** O builder reescreve o `gecko.id` do manifesto para
   `nixos@<nome>`. Native messaging (Proton Pass ↔ app desktop, Pywalfox ↔
   CLI), Sync e o `install_url` do AMO esperam o ID real — então as integrações
   não funcionariam nem se a instalação tivesse dado certo.
3. **`home.packages` levava o xpi no lugar do app desktop.** O binding
   `proton-pass` no `let` do `apps.nix` sombreava o `pkgs.proton-pass` do
   `with pkgs`, então o pacote instalado era a extensão, não o app. Por isso os
   bindings das extensões agora têm sufixo `-extension`.

A migração para o overlay resolve os três: o `buildMozillaXpiAddon` do
rycee/nur-expressions instala em
`share/mozilla/extensions/{ec8030f7-…}/<id-real>.xpi` e **não** toca no
manifesto.

### Bloqueio de YouTube Shorts: filtros do uBO + `userContent.css`

Duas camadas declarativas, porque uma só não cobre os dois modos de falha:

1. **Filtros do uBO** (`user-filters`): bloqueiam a navegação para
   `/shorts/` (`||youtube.com/shorts/$document`) e escondem as prateleiras e
   entradas de Shorts no feed/sidebar/barra do mobile.
2. **`userContent.css`** (pref `toolkit.legacyUserProfileCustomizations.stylesheets`):
   esconde a mesma UI por CSS, cobrindo a janela em que o uBO ainda não carregou
   as listas (primeira execução, listas desatualizadas).

Detalhes que motivaram a implementação:

- O uBO guarda "My filters" em `storage.local` sob a chave **`user-filters`**
  (`µb.userFiltersPath` em `assets.js`), não `userFilters` — usar a chave errada
  gravava o valor e o uBO simplesmente ignorava.
- `programs.firefox.profiles.<p>.extensions.settings` é a via declarativa do
  home-manager (`browser-extension-data/<id>/storage.js`). Exige `force = true`
  (o módulo substitui o `storage.local` inteiro da extensão) e tem como efeito
  colateral desligar `extensions.webextensions.ExtensionStorageIDB.enabled` para
  o perfil.
  - Alternativa avaliada (**não** usada): managed storage via
    `policies."3rdparty".Extensions.<id>.{adminSettings,toOverwrite}`, que é
    não destrutiva (o uBO mescla no startup). Fica como plano B se algum dia
    incomodar o `force = true`.
- Extensão de terceiros tipo "YouTube Shorts Block" via
  `ExtensionSettings.<id>.install_url` foi descartada: instalação em runtime,
  sem hash pinado e com o caminho sendo restringido pela Mozilla.
- Bloqueio por DNS/hosts/Pi-hole foi descartado: o requisito é por site, não de
  rede, e o repo não tem camada de DNS.
- `extensions.autoDisableScopes = 0` é necessário porque as extensões em
  `<perfil>/extensions` entram como *sideload* e, sem isso, o Firefox exige
  habilitação manual na primeira execução (perde-se o "já vem configurado").

**Decisão**: overlay para a origem dos três addons; Shorts por filtros do uBO
(`user-filters`) + `userContent.css`. Manutenção: `nix flake update
firefox-addons` de vez em quando e revisão dos seletores CSS quando o YouTube
mudar o DOM (os filtros do uBO são a camada que de fato bloqueia).

> Nota operacional: se a ativação falhar com
> `mkdir: cannot create directory '<perfil>/extensions': File exists`, é o
> symlink pendurado deixado pela config antiga. O `cleanOldGen` do home-manager
> não o remove (o caminho relativo existe como diretório na geração nova),
> então é preciso tirar o symlink do caminho na mão (`mv` para fora do perfil)
> e reativar. Aconteceu uma vez, na migração.

Referências: [home-manager — Firefox](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.firefox.profiles._name_.extensions.settings),
[uBO — Dashboard: My filters](https://github.com/gorhill/uBlock/wiki/Dashboard:-My-filters),
[uBO — Managed storage](https://github.com/gorhill/uBlock/wiki/Managed-storage).
