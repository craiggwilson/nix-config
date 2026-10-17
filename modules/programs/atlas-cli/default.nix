{
  config.substrate.modules.programs.atlas-cli = {
    provides = [
      "programs:atlas-cli"
      "programming"
    ];
    requires = [ "profiles:work" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.atlas-cli ];
      };
  };
}
