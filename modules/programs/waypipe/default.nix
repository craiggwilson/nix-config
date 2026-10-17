{
  config.substrate.modules.programs.waypipe = {
    provides = [
      "programs:waypipe"
      "gui"
    ];
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          pkgs.waypipe
          pkgs.xauth
        ];
      };
  };
}
