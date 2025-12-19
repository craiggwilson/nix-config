{ inputs, ... }:
let
  sharedHardwareConfig = {
    hdwlinux.hardware = {
      audio.soundcard = {
        busId = "00:1f.3";
        path = "/dev/snd/controlC0";
      };
      graphics = {
        card = {
          busId = "00:02.0";
          path = "/dev/dri/card1";
        };
        nvidia.card = {
          busId = "01:00.0";
          path = "/dev/dri/card0";
        };
      };
      monitors.laptop = {
        vendor = "LG Display";
        model = "0x06B3";
        mode = "1920x1200@59.95Hz";
        scale = 1.0;
      };
      outputProfiles.laptop = {
        outputs.laptop = {
          enable = true;
          position = "0,0";
        };
      };
    };
  };
in
{
  config.substrate.modules.hardware.models.dell-xps-15-9520 = {
    tags = [ "hardware:dell-xps-15-9520" ];

    nixos =
      { pkgs, lib, ... }:
      {
        imports = [
          inputs.nixos-hardware.nixosModules.dell-xps-15-9520-nvidia
        ];

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
      }
      // sharedHardwareConfig;

    homeManager = sharedHardwareConfig;
  };
}
