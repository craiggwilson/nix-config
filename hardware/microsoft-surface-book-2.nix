{ config, lib, pkgs, modulesPath, nixos-hardware, ... }: {

  imports = [
    nixos-hardware.nixosModules.microsoft-surface-common
    nixos-hardware.nixosModules.common-cpu-intel
    nixos-hardware.nixosModules.common-gpu-nvidia
    nixos-hardware.nixosModules.common-pc
    nixos-hardware.nixosModules.common-pc-ssd
    nixos-hardware.nixosModules.common-hidpi 
  ];

  # IPTSD has problems shutting down, in that, it doesn't.
  # Basically, can't shutdown or reboot.
  # microsoft-surface.ipts.enable = true; 

  microsoft-surface.surface-control.enable = true;

  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" "v4l2loopback" ];
    kernelParams = [ "i915.enable_psr=0" "i915.fastboot=1" ];
    extraModulePackages = with config.boot.kernelPackages;[ 
      v4l2loopback.out 
    ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
    '';
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  environment.systemPackages = with pkgs; [ 
    libcamera
    nvtop 
  ];

  hardware = {
    bumblebee = {
      enable = true;
    };
    nvidia = {
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

  # Touchpad
  services.xserver.libinput.enable = true;
}
