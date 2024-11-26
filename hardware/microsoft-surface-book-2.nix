{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
{

  imports = [
    inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
    #inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-hidpi
  ];

  hdwlinux = {
    hardware = {
      graphics = {
        card = {
          busId = "00:02.0";
        };
        nvidia = {
          card = {
            busId = "02:00.0";
          };
        };
      };
    };

    tags = [
      #"audio"
      "bluetooth"
      "boot:systemd"
      "camera"
      "laptop"
      "networking"
      #"nvidia"
    ];
  };

  boot = {
    blacklistedKernelModules = [ "snd_hda_intel" ]; # audio is flickering on and off, so disable sound.
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "i915.enable_psr=0"
      "i915.fastboot=1"
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
