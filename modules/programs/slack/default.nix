{
  config.substrate.modules.programs.slack = {
    provides = [
      "programs:slack"
      "gui"
    ];
    requires = [ "profiles:work" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.slack
          pkgs.hdwlinux.slackcli
        ];
      };
  };
}
