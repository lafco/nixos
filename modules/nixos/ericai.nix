# Agente ericai (ZeroClaw): wiring específico do host "daily".
#
# O grosso da config está no flake do projeto (importado acima dele na lista
# de módulos como `inputs.ericai.nixosModules.ericai`); aqui ficam só as
# amarras locais:
#
# - O token do Telegram vem do sops (secrets/secrets.yaml → "zeroclaw/ericai-env").
#   O valor do segredo é a linha `BOT_TOKEN=...` (formato yaml padrão — o
#   sops-nix escreve o valor decriptado como arquivo, servindo direto de
#   EnvironmentFile= do systemd; não pode ser `dotenv` porque os outros
#   segredos do mesmo arquivo são yaml).
# - Ordenação: o serviço zeroclaw-ericai só sobe depois que o sops-nix
#   decripta os segredos no boot (sops-install-secrets.service).
{ config, ... }:
{
  # Nesta máquina o sops-nix está no modo "activation script" (segredos só
  # existem após um nixos-rebuild; um reboot limpa o /run e o zeroclaw-ericai
  # nunca subiria — ConditionPathExists falharia). Força o modo systemd, que
  # instala os segredos via sops-install-secrets.service a cada boot (o
  # zeroclaw-ericai já depende dele via after/requires abaixo).
  sops.useSystemdActivation = true;

  services.zeroclaw.instances.ericai.environmentFile =
    config.sops.secrets."zeroclaw/ericai-env".path;

  # Sobe o zeroclaw-ericai depois dos segredos decriptados.
  systemd.services.zeroclaw-ericai = {
    after = [ "sops-install-secrets.service" ];
    requires = [ "sops-install-secrets.service" ];
  };

  # Token do bot (criar em secrets/secrets.yaml; `sops edit` na raiz do repo).
  sops.secrets."zeroclaw/ericai-env" = { };
}
