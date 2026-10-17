{
  config.substrate.modules.hardware.camera = {
    provides = [ "hardware:camera" ];
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.libcamera ];
      };
  };
}
