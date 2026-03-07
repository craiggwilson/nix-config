{
  config.substrate.modules.programs.procps = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.procps ];
    };
  };
}

