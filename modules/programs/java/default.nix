{
  config.substrate.modules.programs.java = {
    provides = [ "programming" ];
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
