{
  config.substrate.modules.programs.java = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = with pkgs; [
          temurin-bin-21
          maven
        ];
      };
  };
}

