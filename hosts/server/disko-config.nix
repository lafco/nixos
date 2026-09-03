# Layout de disco do servidor (VPS típico: BIOS + ext4, simples).
# Ajuste `device`: /dev/vda (KVM/Proxmox), /dev/sda (bare metal), /dev/nvme0n1, etc.
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02"; # BIOS boot (GRUB)
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
