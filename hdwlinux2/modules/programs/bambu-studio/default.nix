{
  config.substrate.modules.programs.bambu-studio = {
    tags = [
      "users:craig:personal"
      "users:craig"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.bambu-studio ];
      };
  };
}
