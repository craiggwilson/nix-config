{
  config.substrate.modules.programs.pciutils = {
    provides = [
      "programs:pciutils"
      "core:networking"
    ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.pciutils ];
    };
  };
}
