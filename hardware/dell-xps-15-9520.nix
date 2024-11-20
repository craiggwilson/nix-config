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
    audio.soundcardBusId = "00:1f.3";

    features = {
      tags = [
        "audio"
        "bluetooth"
        "boot:systemd"
        "camera"
        "fingerprint"
        "laptop"
        "networking"
        "thunderbolt"
        "video:nvidia"
        "video:v4l2loopback"
      ];
    };

    video = {
      integrated = {
        vendor = "intel";
        busId = "PCI:00:02:0";
        path = "/dev/dri/card1";
      };

      discrete = {
        vendor = "nvidia";
        busId = "PCI:01:00:0";
        path = "/dev/dri/card0";
      };
    };
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
