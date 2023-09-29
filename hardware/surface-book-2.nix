{ config, lib, pkgs, modulesPath, ... }: {
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

  microsoft-surface.surface-control.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  environment.systemPackages = with pkgs; [ 
    libcamera
    nvtop 
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  services.xserver.videoDrivers = [ "nvidia" "intel" ];

  hardware = {
    bumblebee = {
      enable = true;
    };
    nvidia = {
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
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
      extraPackages = with pkgs; [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  };
}
