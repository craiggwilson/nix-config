{
  config.substrate.modules.programs.libcamera = {
    tags = [ "capability:camera" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.libcamera ];
    };
  };
}
