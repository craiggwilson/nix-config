{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:

let
  cfg = config.hdwlinux.hardware.models.system76-serval-ws;
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel # also includes intel GPU
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.system76
  ];

  options.hdwlinux.hardware.models.system76-serval-ws = {
    enable = lib.mkEnableOption "system76-serval-ws";
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
        monitors.laptop = {
          vendor = "BOE";
          model = "0x0A1C";
          mode = "1920x1080@165.004Hz";
          scale = 1.0;
        };
      };

      outputProfiles.laptop.outputs = [
        {
          monitor = "laptop";
          enable = true;
          position = "0,0";
        }
      ];

      tags = [
        "audio"
        "bluetooth"
        "camera"
        "fingerprint"
        "graphics:nvidia"
        "laptop"
        "networking"
        "thunderbolt"
      ];

    };

    boot = {
      initrd = {
        availableKernelModules = [
          "xhci_pci"
          "nvme"
          "usb_storage"
          "usbhid"
          "sd_mod"
          "sdhci_pci"
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

    environment.systemPackages = [
      pkgs.system76-firmware
      pkgs.system76-keyboard-configurator
    ];
  };
}
