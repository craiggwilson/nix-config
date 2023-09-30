{ config, lib, pkgs, modulesPath, nixos-hardware, ... }: {

  imports = [
    nixos-hardware.nixosModules.dell-xps-15-9520-nvidia
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "thunderbolt" "vmd" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" "v4l2loopback" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ ];
    extraModulePackages = with config.boot.kernelPackages; [ 
      v4l2loopback.out 
    ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
    '';
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  hardware.enableRedistributableFirmware = true;

  hardware = {
    nvidia = {
      modesetting.enable = true;
    };
    opengl = {
      enable = true;
      driSupport32Bit = true;
      driSupport = true;
    };
  };

  services.xserver.libinput.enable = true;
  services.thermald.enable = true;
  services.hardware.bolt.enable = true;

  environment.systemPackages = with pkgs; [ 
    libcamera
    lshw
    neofetch
    nvtop 
    pciutils
  ];
}
