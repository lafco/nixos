#!/usr/bin/env bash
# Aplica os dotfiles na MÁQUINA DA EMPRESA (home-manager standalone).
# Rode este script dentro do repo, na própria máquina do trabalho.
set -euo pipefail

exec home-manager switch --flake ".#lafco@work"
