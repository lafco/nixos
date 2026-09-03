{
  description = "Config declarativa: NixOS daily (XFCE), servidor headless e home-manager para a máquina da empresa (dotfiles em lafco/config)";

  inputs = {
    # NixOS estável 26.05
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Para pacotes que ainda não chegaram no estável (pi-coding-agent, herdr) —
    # usados via pkgs.unstable.* (ver lib/overlays.nix).
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Obs.: o repo de dotfiles (github:lafco/config, stow + CLI `dot`) NÃO é
    # mais um input — ele é clonado em ~/dotfiles pelo instalador e os
    # symlinks são feitos por home/modules/dotfiles.nix.

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Segredos encriptados (age/sops) — veja docs/bootstrap.md.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Particionamento declarativo — usado pelo nixos-anywhere na instalação.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Formatação centralizada (`nix fmt`).
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ══ Lix (alternativa ao Nix oficial) ═══════════════════════════════
    # Se preferir o Lix (fork comunitário), descomente e adicione o módulo
    # abaixo à lista `modules` de cada host. É drop-in: o resto não muda.
    # Mais detalhes em docs/decisions.md.
    #
    # lix-module = {
    #   url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs =
    inputs @ {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
      disko,
      treefmt-nix,
      ...
    }:
    let
      lib = import ./lib;
      inherit (lib) forAllSystems;

      # Overlays compartilhados (unstable + compat nodePackages/intelephense).
      overlays = import ./lib/overlays.nix { inherit inputs; };

      # Liga o home-manager (modo módulo) ao nixpkgs do sistema.
      hmSystem = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        # Deixa os inputs disponíveis para os módulos home-manager
        # (ex.: home/modules usa pkgs.unstable.*, vindo do overlay).
        home-manager.extraSpecialArgs = { inherit inputs; };
      };
    in
    {
      # ── Máquina de uso diário (NixOS + XFCE) ───────────────────────
      nixosConfigurations.daily = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/daily
          ./modules/nixos/common.nix
          ./modules/nixos/desktop.nix
          ./modules/nixos/gaming.nix
          ./modules/nixos/torrents.nix
          ./modules/nixos/database.nix
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          hmSystem
        ];
      };

      # ── Servidor headless mínimo para desenvolvimento ──────────────
      nixosConfigurations.server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/server
          ./modules/nixos/common.nix
          ./modules/nixos/server.nix
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          hmSystem
        ];
      };

      # ── Máquina da empresa: home-manager STANDALONE (Ubuntu/Debian) ─
      # Ativação: home-manager switch --flake .#lafco@work
      homeConfigurations."lafco@work" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          inherit overlays;
        };
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./home/lafco
          ./home/lafco/standalone.nix
          ./home/profiles/work.nix
          # Segredos na máquina do trabalho (opcional): descomente quando for
          # usar e crie secrets/secrets.yaml primeiro (docs/bootstrap.md).
          # sops-nix.homeManagerModules.sops
          # {
          #   sops = {
          #     defaultSopsFile = ../../secrets/secrets.yaml;
          #     age.keyFile = "/home/lafco/.config/sops/age/keys.txt";
          #   };
          # }
        ];
      };

      # ── DevShell para mexer neste repo (`nix develop`) ─────────────
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nixfmt # nix fmt
              age # gerar/editar chaves age
              ssh-to-age # converter chaves SSH em age (secrets do servidor)
              sops # editar secrets/secrets.yaml
              nil # LSP nix (use junto com nixd no editor)
              nixos-anywhere # instalar NixOS remotamente
            ];
          };
        }
      );

      # ── Formatador (`nix fmt`) ─────────────────────────────────────
      formatter = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        treefmt-nix.lib.mkWrapper pkgs (import ./treefmt.nix)
      );
    };
}
