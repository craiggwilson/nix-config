{ disks, ...}: {
  disko.devices.disk.nvme0n1 = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          type = "EF00";
          size = "512M";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "defaults"
            ];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "crypted-root";
            settings = {
              allowDiscards = true;
            };
            passwordFile = "/tmp/secret.key";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              mountpoint = "/";
              mountOptions = ["discard" "noatime"];
              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = ["compress=zstd noatime"];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                # "/swap" = {
                #   mountpoint = "/.swapvol";
                #   swap.swapfile.size = "4G";
                # };
              };
            };
          };
        };
      };
    };
  };
}