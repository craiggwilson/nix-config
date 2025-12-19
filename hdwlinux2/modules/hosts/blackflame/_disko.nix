{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02"; # for grub MBR
        };
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        swap = {
          size = "96G";
          content = {
            type = "swap";
            randomEncryption = true;
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "crypted";
            passwordFile = "/tmp/secret.key";
            settings = {
              allowDiscards = true;
            };
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "SYSTEM" = { };
                "SYSTEM/root" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "SYSTEM/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "DATA" = { };
                "DATA/home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
}
