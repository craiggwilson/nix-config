{
  config.substrate.modules.programs.tree = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.tree ];
    };
  };
}

