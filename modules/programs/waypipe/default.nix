{
  config.substrate.modules.programs.waypipe = {
    provides = [ "gui" ];
    tags = [ "gui" ];

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
