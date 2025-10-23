{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:

let
  cfg = config.hdwlinux.hardware.models.dell-xps-15-9520;
in
{
  imports = [ inputs.nixos-hardware.nixosModules.dell-xps-15-9520-nvidia ];

  options.hdwlinux.hardware.models.dell-xps-15-9520 = {
    enable = lib.mkEnableOption "dell-xps-15-9520";
  };

  config = lib.mkIf cfg.enable {
    hdwlinux = {
      hardware = {
        audio = {
          soundcard = {
            busId = "00:1f.3";
            path = "/dev/snd/controlC0";
          };
        };
        graphics = {
          card = {
            busId = "00:02.0";
            path = "/dev/dri/card1";
          };
          nvidia = {
            card = {
              busId = "01:00.0";
              path = "/dev/dri/card0";
            };
          };
        };
      };

      tags = [
        "audio"
        "bluetooth"
        "camera"
        "fingerprint"
        "laptop"
        "networking"
        "nvidia"
        "thunderbolt"
      ];
    };

    boot = {
      initrd = {
        availableKernelModules = [
          "xhci_pci"
          "vmd"
          "nvme"
          "usb_storage"
          "sd_mod"
          "rtsx_pci_sdmmc"
        ];
        kernelModules = [ ];
      };
      kernelModules = [ "kvm-intel" ];
      kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
      kernelParams = [ ];
      kernel.sysctl = {
        "fs.inotify.max_user_watches" = "1048576";
      };
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

    services = {
      thermald.enable = true;
      tlp.enable = true;
    };
  };
}
