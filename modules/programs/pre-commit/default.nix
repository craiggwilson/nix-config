{
  config.substrate.modules.programs.pre-commit = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.pre-commit ];
      };
  };
}

