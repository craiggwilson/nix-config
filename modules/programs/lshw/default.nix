{
  config.substrate.modules.programs.lshw = {
    provides = [ "core:networking" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.lshw ];
    };
  };
}
