{
  config.substrate.modules.programs.libcamera = {
    provides = [ "programs:libcamera" "hardware:camera" ];
    tags = [ "camera" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.libcamera ];
    };
  };
}
