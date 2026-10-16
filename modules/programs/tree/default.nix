{
  config.substrate.modules.programs.tree = {
    provides = [ "core:utils" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.tree ];
    };
  };
}
