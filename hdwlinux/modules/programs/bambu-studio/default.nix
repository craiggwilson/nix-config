{
  config.substrate.modules.programs.bambu-studio = {
    tags = [
      "users:craig:personal"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.stable.bambu-studio ];
      };
  };
}
