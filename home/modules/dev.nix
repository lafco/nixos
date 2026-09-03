# Runtimes e ferramentas de desenvolvimento (core — todas as máquinas).
#
# nodejs_22 e python3 também são usados pelos plugins do nvim (editor.nix);
# repetir aqui é inofensivo e deixa a intenção explícita.
#
# Rust: toolchain estável do nixpkgs (cargo/rustc/rustfmt/clippy). Se um dia
# precisar de múltiplas toolchains/rustup, troque por:
#   rustup  # + variáveis RUSTUP_HOME/CARGO_HOME e PATH ~/.cargo/bin
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # rust
    cargo
    rustc
    rustfmt
    clippy

    # javascript/typescript
    nodejs_22
    deno
    bun

    # python
    python3

    # banco de dados (cliente psql; o SERVIDOR fica em modules/nixos/database.nix)
    postgresql
  ];
}
