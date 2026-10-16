{
  config.substrate.modules.programs.atlas-cli = {
    provides = [ "programs:atlas-cli" "programming" ];
    requires = [ "profiles:work" ];
    tags = [
      "programming"
      "users:craig:work"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.atlas-cli ];
      };
  };
}
