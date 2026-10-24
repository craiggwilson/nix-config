{
  config.substrate.modules.programs.calibre = {
    tags = [
      "desktop"
      "profile:personal"
    ];

    homeManager =
      { pkgs, ... }:
      {
        programs.calibre = {
          enable = true;
          package = pkgs.calibre.override { speechSupport = false; };
        };
      };
  };
}
