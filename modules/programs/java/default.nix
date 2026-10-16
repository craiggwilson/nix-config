{
  config.substrate.modules.programs.java = {
    provides = [ "programs:java" "programming" ];
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          temurin-bin-21
          maven
        ];
      };
  };
}
