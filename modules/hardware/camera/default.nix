{
  config.substrate.modules.hardware.camera = {
    tags = [ "capability:camera" ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.libcamera ];
      };
  };
}
