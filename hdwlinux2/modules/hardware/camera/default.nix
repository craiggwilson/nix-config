{
  config.substrate.modules.hardware.camera = {
    tags = [ "camera" ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.libcamera ];
      };
  };
}

