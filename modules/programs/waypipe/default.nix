{
  config.substrate.modules.programs.waypipe = {
    tags = [ "desktop" ];

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
