{
  config.substrate.modules.programs.lshw = {
    provides = [
      "programs:lshw"
      "core:networking"
    ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.lshw ];
    };
  };
}
