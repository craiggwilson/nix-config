{
  config.substrate.modules.programs.libcamera = {
    provides = [
      "programs:libcamera"
      "hardware:camera"
    ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.libcamera ];
    };
  };
}
