{
  config.substrate.modules.programs.waypipe = {
    tags = [ "gui" ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          pkgs.waypipe
          pkgs.xorg.xauth
        ];
      };
  };
}

