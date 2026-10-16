{
  config.substrate.modules.programs.pciutils = {
    provides = [ "core:networking" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.pciutils ];
    };
  };
}
