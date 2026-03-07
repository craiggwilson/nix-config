{ inputs, ... }:
{
  config.substrate.modules.hardware.models.system76-serval-ws = {
    tags = [ "hardware:system76-serval-ws" ];

    generic = {
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
          vendor = "BOE";
          model = "0x0A1C";
          mode = "1920x1080@165.004Hz";
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

    nixos =
      { pkgs, lib, ... }:
      {
        imports = [
          inputs.nixos-hardware.nixosModules.common-cpu-intel
          inputs.nixos-hardware.nixosModules.common-pc-ssd
          inputs.nixos-hardware.nixosModules.system76
        ];

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
          kernel.sysctl = {
            "fs.inotify.max_user_watches" = "1048576";
          };
        };

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

        environment.systemPackages = [
          pkgs.system76-firmware
          pkgs.system76-keyboard-configurator
        ];
      };

    homeManager =
      { pkgs, ... }:
      {
        hdwlinux.programs.hdwlinux = {
          runtimeInputs = [ pkgs.system76-power ];
          subcommands = {
            battery = {
              set-profile = "system76-power charge-thresholds --profile \"$@\"";
              "*" = "system76-power charge-thresholds";
            };
            firmware = {
              update = "sudo system76-firmware-cli schedule";
            };
          };
        };
      };
  };
}
