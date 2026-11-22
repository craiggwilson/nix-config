{
  config.substrate.modules.programs.evergreen.options = {
    tags = [ "profile:programming" ];

    homeManager =
      { lib, pkgs, ... }:
      {
        options.hdwlinux.programs.evergreen.package = lib.mkOption {
          default = pkgs.hdwlinux.evergreen;
          description = "Evergreen CLI package to install.";
          type = lib.types.package;
        };
      };
  };
}
