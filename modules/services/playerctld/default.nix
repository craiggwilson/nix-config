{
  config.substrate.modules.services.playerctld = {
    provides = [
      "services:playerctld"
      "gui"
    ];
    requires = [ "hardware:audio" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.playerctl ];
        services.playerctld.enable = true;
      };
  };
}
