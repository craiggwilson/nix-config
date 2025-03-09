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
          sign-on-push = true;
          subprocess = true;
        };

        merge-tools.difft = {
          program = "${pkgs.difftastic}/bin/difft";
          diff-args = [
            "--color=always"
            "$left"
            "$right"
          ];
        };

        merge-tools.meld = {
          program = "${pkgs.meld}/bin/meld";
          edit-args = [
            "--newtab"
            "$left"
            "$right"
          ];
          merge-args = [
            "$left"
            "$base"
            "$right"
            "-o"
            "$output"
            "--auto-merge"
          ];
        };

        signing = {
          behavior = "own";
          backend = "ssh";
          key = "~/.ssh/id_rsa";
        };

        ui = {
          default-command = [ "log" ];
          diff-editor = "meld-3";
          diff.format = "git";
          diff.tool = "difft";
          merge-editor = "meld";
          pager = "${pkgs.delta}/bin/delta";
        };

        user = {
          email = config.hdwlinux.user.email;
          name = config.hdwlinux.user.fullName;
        };

      };
    };
  };
}
