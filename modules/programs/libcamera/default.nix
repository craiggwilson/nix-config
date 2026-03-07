{
  config.substrate.modules.programs.libcamera = {
    tags = [ "camera" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.libcamera ];
    };
  };
}

