{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{

  imports = [ inputs.nixos-hardware.nixosModules.dell-xps-15-9520-nvidia ];

  hdwlinux.features = {
    tags = [
      "audio"
      "bluetooth"
      "boot:systemd"
      "camera"
      "fingerprint"
      "networking"
      "redistributableFirmware"
      "v4l2loopback"
    ];
  };

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
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
    pkgs.firmware-manager
    pkgs.system76-keyboard-configurator
  ];

  services = {
    hardware.bolt.enable = true;
  };

  hardware = {
    nvidia = {
      modesetting.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      # prime = {
      #   sync.enable = true;
      #   intelBusId = "PCI:0:2:0";
      #   nvidiaBusId = "PCI:1:0:0";
      # };
    };
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    system76.enableAll = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
