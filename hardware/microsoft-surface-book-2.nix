{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{

  imports = [
    inputs.nixos-hardware.nixosModules.microsoft-surface-common
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.common-hidpi
  ];

  hdwlinux.features = {
    tags = [
      "audio"
      "bluetooth"
      "boot:systemd"
      "camera"
      "networking"
      "redistributableFirmware"
      "v4l2loopback"
    ];
  };

  boot = {
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

  hardware = {
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = {
        intelBusId = "PCI:00:02:0";
        nvidiaBusId = "PCI:02:00:0";
      };
      modesetting.enable = true;
      nvidiaPersistenced = false;
    };
    opengl = {
      enable = true;
      driSupport32Bit = true;
      driSupport = true;
    };
  };

  # IPTSD has problems shutting down, in that, it doesn't.
  # Basically, can't shutdown or reboot.
  # microsoft-surface.ipts.enable = true; 
  microsoft-surface.surface-control.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
