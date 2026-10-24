{
  config.substrate.modules.programs.java = {
    tags = [ "profile:programming" ];

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
