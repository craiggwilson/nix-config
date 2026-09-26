{
  config.substrate.modules.programs.minder = {
    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.minder ];
      };
  };
}

