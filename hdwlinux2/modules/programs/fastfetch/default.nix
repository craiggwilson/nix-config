{
  config.substrate.modules.programs.fastfetch = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.fastfetch ];
    };
  };
}

