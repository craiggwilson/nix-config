{
  config.substrate.modules.programs.pre-commit = {
    provides = [
      "programs:pre-commit"
      "programming"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.pre-commit ];
      };
  };
}
