{
  config.substrate.modules.programs.tree = {
    provides = [
      "programs:tree"
      "core:utils"
    ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.tree ];
    };
  };
}
