{
  config.substrate.modules.programs.pciutils = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.pciutils ];
    };
  };
}

