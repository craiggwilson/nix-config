{ config, lib, pkgs, modulesPath, ... }: {

  imports = [

  ];

  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" "v4l2loopback" ];
    kernelParams = [ ];
    extraModulePackages = with config.boot.kernelPackages;[ 
      v4l2loopback.out 
    ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
    '';
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  environment.systemPackages = with pkgs; [ 
    nvtop 
  ];

  hardware = {
    bumblebee = {
      enable = true;
    };
    opengl = {
      enable = true;
      driSupport32Bit = true;
      driSupport = true;
      extraPackages = with pkgs; [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  };

  # Touchpad
  services.xserver.libinput.enable = true;
}
