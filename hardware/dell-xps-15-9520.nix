{ config, lib, pkgs, modulesPath, nixos-hardware, ... }: {

  imports = [
    nixos-hardware.nixosModules.common-cpu-intel
    nixos-hardware.nixosModules.common-gpu-nvidia
    nixos-hardware.nixosModules.common-pc-laptop
    nixos-hardware.nixosModules.common-pc-laptop-ssd
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "thunderbolt" "vmd" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" "v4l2loopback" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ ];
    extraModulePackages = with config.boot.kernelPackages;[ 
      v4l2loopback.out 
    ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
    '';
  #    options iwlwifi power_save=1 disable_11ax=1
  };

  

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  environment.systemPackages = with pkgs; [ 
    libcamera
    lshw
    neofetch
    nvtop 
  ];

  hardware = {
    bumblebee = {
      enable = true;
    };
    nvidia = {
      prime = {
        intelBusId = "PCI:00:02:0";
        nvidiaBusId = "PCI:01:00:0";
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

  # Touchpad
  services.xserver.libinput.enable = true;

  services.xserver.videoDrivers = [ "nvidia" "intel" ];

  services.thermald.enable = lib.mkDefault true;
}
