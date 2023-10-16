{ pkgs, lib, inputs, config, ... }: {

  imports = [
    inputs.nixos-hardware.nixosModules.dell-xps-15-9520-nvidia
  ];

  hdwlinux.packages = {
    audio.enable = true;
    bluetooth.enable = true;
    boot.enable = true;
    fingerprint.enable = true;
    libcamera.enable = true;
    networking.enable = true;
    printing.enable = true;
    redistributableFirmware.enable = true;
    thunderbolt.enable = true;
    v4l2loopback.enable = true;
  };

  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "vmd" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  hardware = {
    nvidia = {
      modesetting.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    opengl = {
      enable = true;
      driSupport32Bit = true;
      driSupport = true;
    };
  };

  services.thermald.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
