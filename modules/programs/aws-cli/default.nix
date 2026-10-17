{
  config.substrate.modules.programs.aws-cli = {
    provides = [
      "programs:aws-cli"
      "profiles:work"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.awscli2 ];
      };
  };
}
