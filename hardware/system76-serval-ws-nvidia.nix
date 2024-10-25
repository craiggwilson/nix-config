{
  config,
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

  boot = lib.mkIf (config.specialisation != { }) {
    extraModprobeConfig = ''
      blacklist nouveau
      options nouveau modeset=0
    '';

    blacklistedKernelModules = [
      "nvidia"
      "nvidia_drm"
      "nvidia_modeset"
    ];
  };

  services.udev.extraRules = lib.mkIf (config.specialisation != { }) ''
    # Remove NVIDIA USB xHCI Host Controller devices, if present
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"
    # Remove NVIDIA USB Type-C UCSI devices, if present
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"
    # Remove NVIDIA Audio devices, if present
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"
    # Remove NVIDIA VGA/3D controller devices
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
  '';

  specialisation.nvidia.configuration = {
    hdwlinux.features = {
      tags = [
        "video:nvidia"
      ];

      video.nvidiaBusId = "PCI:01:00:0";
    };
  };
}
