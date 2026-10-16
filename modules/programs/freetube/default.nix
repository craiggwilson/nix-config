{
  config.substrate.modules.programs.freetube = {
    provides = [ "programs:freetube" "gui" ];
    requires = [ "profiles:personal" ];
    tags = [
      "gui"
      "users:craig:personal"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.freetube ];
      };
  };
}
