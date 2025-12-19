{ lib, ... }:
{
  config.substrate.modules.programs.evergreen = {
    tags = [ "programming" "users:craig:work" ];

    homeManager =
      { config, pkgs, ... }:
      let
        cfg = config.hdwlinux.programs.evergreen;
      in
      {
        options.hdwlinux.programs.evergreen = {
          configFile = lib.mkOption {
            type = lib.types.str;
            default = "${config.home.homeDirectory}/.evergreen.yml";
            description = "Path to the evergreen configuration file";
          };
        };

        config = {
          home.packages = [
            (pkgs.writeScriptBin "evergreen" ''
              ${pkgs.hdwlinux.evergreen}/bin/evergreen --config "${cfg.configFile}" "$@"
            '')
          ];
        };
      };
  };
}

