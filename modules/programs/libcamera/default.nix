{
  config.substrate.modules.programs.libcamera = {
    provides = [ "hardware:camera" ];
    tags = [ "camera" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.libcamera ];
    };
  };
}
