{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{

  imports = [ inputs.nixos-hardware.nixosModules.dell-xps-15-9520-nvidia ];

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
    kernelPackages = lib.mkDefault pkgs.linuxPackages_6_12;
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
