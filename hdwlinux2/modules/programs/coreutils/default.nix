{
  config.substrate.modules.programs.coreutils = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.coreutils ];
    };
  };
}

