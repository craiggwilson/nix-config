{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{

  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel # also includes intel GPU
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.system76
  ];

  hdwlinux.features = {
    tags = [
      "audio"
      "bluetooth"
      "boot:systemd"
      "camera"
      "fingerprint"
      "networking"
      "redistributableFirmware"
      "thunderbolt"
      "video:nvidia"
      "video:v4l2loopback"
    ];

    audio.soundcardPciId = "00:1f.3";
    video.intelBusId = "PCI:00:02:0";
    video.nvidiaBusId = "PCI:01:00:0";
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
    pkgs.firmware-manager
    pkgs.system76-keyboard-configurator
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
