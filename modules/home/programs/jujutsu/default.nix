{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.jujutsu;
in
{
  options.hdwlinux.programs.jujutsu = {
    enable = config.lib.hdwlinux.mkEnableOption "jujutsu" "programming";
  };

  config = lib.mkIf cfg.enable {
    programs.jujutsu = {
      enable = true;

      settings = {
        git = {
          colocate = true;
          sign-on-push = true;
          subprocess = true;
        };

        signing = {
          behavior = "own";
          backend = "ssh";
          key = "~/.ssh/id_rsa";
        };

        snapshot = {
          auto-update-stale = true;
        };

        ui = {
          default-command = [ "log" ];
          diff.format = "git";
        };

        user = {
          email = config.hdwlinux.user.email;
          name = config.hdwlinux.user.fullName;
        };
      };
    };
  };
}
