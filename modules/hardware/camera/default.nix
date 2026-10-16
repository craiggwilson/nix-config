{
  config.substrate.modules.hardware.camera = {
    provides = [ "hardware:camera" ];
    tags = [ "camera" ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.libcamera ];
      };
  };
}
