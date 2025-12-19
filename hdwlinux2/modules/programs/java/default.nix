{
  config.substrate.modules.programs.java = {
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

