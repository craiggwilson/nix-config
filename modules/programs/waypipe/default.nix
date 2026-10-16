{
  config.substrate.modules.programs.waypipe = {
    provides = [ "programs:waypipe" "gui" ];
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
