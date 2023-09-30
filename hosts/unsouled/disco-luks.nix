{ disks, ...}: {
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "table";
      format = "gpt";
      partitions = [
        {
          name = "boot";
          start = "0";
          end = "1MiB";
          flags = [ "bios_grub" ];
        }
        {
          name = "ESP";
          start = "1MiB";
          end = "512MiB";
          bootable = true;
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        }
        {
          name = "root";
          start = "512MiB";
          end = "100%";
          content = {
            name = "crypted";
            type = "luks";
            passwordFile = "/tmp/secret.key";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              mountpoint = "/";
              mountOptions = ["discard" "noatime"];
              subvolumes = {
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = ["compress=zstd" "noatime"];
                };
              };
            };
          };
        }
      ];
    };
  };
}
