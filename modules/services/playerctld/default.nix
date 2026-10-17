{
  config.substrate.modules.services.playerctld = {
    provides = [
      "services:playerctld"
      "gui"
    ];
    requires = [
      "gui"
      "hardware:audio"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.playerctl ];
        services.playerctld.enable = true;
      };
  };
}
