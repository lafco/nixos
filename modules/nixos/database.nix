# Postgres local para desenvolvimento (só na daily).
#
# - Socket local, sem TCP (não expõe nada na rede; firewall intocado).
# - Auth "trust" no socket/loopback (padrão do módulo no NixOS): `psql` já
#   entra direto com o usuário lafco.
# - Banco e role `lafco` criados automaticamente no primeiro boot.
{ ... }:
{
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "lafco" ];
    ensureUsers = [
      {
        name = "lafco";
        ensureDBOwnership = true;
      }
    ];
  };
}
