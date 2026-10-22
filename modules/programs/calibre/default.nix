{
  config.substrate.modules.programs.calibre = {
    tags = [
      "desktop"
      "users:craig:personal"
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
