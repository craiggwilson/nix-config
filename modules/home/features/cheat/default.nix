{
  options,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.cheat;
  xdgConfigHome = config.xdg.configHome;
  communityCheats = builtins.fetchGit {
    url = "https://github.com/cheat/cheatsheets";
    rev = "36bdb99dcfadde210503d8c2dcf94b34ee950e1d";
  };
in
{
  options.hdwlinux.features.cheat = with types; {
    enable = mkEnableOpt [ "cli" ] config.hdwlinux.features.tags;
    enableCommunity = mkBoolOpt true "Whether to enable the community cheats.";
    settings = mkOption {
      description = "Settings for cheat.";
      default = { };
      type = submodule {
        options = {
          colorize = mkOption {
            default = true;
            type = bool;
          };
          formatter = mkOption {
            default = "terminal256";
            type = str;
          };
          style = mkOption {
            default = if config.hdwlinux.theme.enable then config.hdwlinux.theme.name else "monokai";
            type = str;
          };
          cheatpaths = mkOption {
            description = "Cheatpaths";
            default = [ ];
            type = listOf (
              submodule (
                { config, ... }:
                {
                  options = {
                    name = mkOption { type = str; };
                    path = mkOption {
                      type = path;
                      default = "${xdgConfigHome}/cheats/cheatsheets/${config.name}";
                    };
                    tags = mkOption { type = listOf str; };
                    readonly = mkOption {
                      type = bool;
                      default = false;
                    };
                  };
                }
              )
            );
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ cheat ];

    xdg.configFile."cheat/conf.yml".text = # builtins.toJSON cfg.settings;
      let
        settings = {
          inherit (cfg.settings) colorize formatter style;
          cheatpaths =
            lib.optionals cfg.enableCommunity [
              {
                name = "community";
                tags = [ "community" ];
                path = communityCheats;
                readonly = true;
              }
            ]
            ++ cfg.settings.cheatpaths;
        };
      in
      builtins.toJSON settings;
  };
}
