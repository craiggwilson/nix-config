{
  config.substrate.modules.programs.lshw = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.lshw ];
    };
  };
}

