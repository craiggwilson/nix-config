{
  pkgs,
  lib,
  inputs,
  ...
}:
{

  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel # also includes intel GPU
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.system76
  ];

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
        busId = "00:02.0";
        path = "/dev/dri/card1";
      };

      discrete = {
        vendor = "nvidia";
        busId = "01:00.0";
        path = "/dev/dri/card0";
      };
    };
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

  /*
    echo '1' > '/sys/module/snd_hda_intel/parameters/power_save';
    echo 'auto' > '/sys/bus/pci/devices/0000:00:1c.4/power/control';
    echo 'auto' > '/sys/bus/pci/devices/0000:00:14.2/power/control'
    echo 'auto' > '/sys/bus/pci/devices/0000:00:1a.0/power/control
    echo 'auto' > '/sys/bus/pci/devices/0000:2c:00.0/power/control'
    echo 'auto' > '/sys/bus/pci/devices/0000:00:00.0/power/control'
    echo 'auto' > '/sys/bus/pci/devices/0000:00:1f.5/power/control'
    echo 'auto' > '/sys/bus/pci/devices/0000:36:00.0/power/control'
    echo 'auto' > '/sys/bus/pci/devices/0000:00:14.3/power/control'
    echo 'auto' > '/sys/bus/pci/devices/0000:38:00.0/power/control'
    echo 'auto' > '/sys/bus/pci/devices/0000:37:00.0/power/control'
    echo 'auto' > '/sys/bus/pci/devices/0000:00:1f.0/power/control'
    echo 'auto' > '/sys/bus/pci/devices/0000:00:0a.0/power/control'
  */

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
