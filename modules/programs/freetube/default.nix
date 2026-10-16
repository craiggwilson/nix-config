{
  config.substrate.modules.programs.freetube = {
    provides = [ "gui" ];
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
