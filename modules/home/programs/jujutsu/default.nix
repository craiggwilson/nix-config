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
    home.packages = [
      pkgs.gg-jj
      pkgs.jjui
    ];

    programs.jujutsu = {
      enable = true;

      settings = {
        core = {
          fsmonitor = "watchman";
          watchman.register_snapshot_trigger = true;
        };

        git = {
          colocate = true;
          private-commits = "description(glob:'private:*')";
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

    xdg.configFile."micro/syntax/jjdescription.yaml".source = ./micro-syntax.yaml;
  };
}
