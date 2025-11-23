{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.meld;
in
{
  options.hdwlinux.programs.meld = {
    enable = config.lib.hdwlinux.mkEnableOption "meld" [ "gui" ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.meld ];

    programs.git.settings = lib.mkIf config.hdwlinux.programs.git.enable {
      merge.tool = "${pkgs.meld}/bin/meld";
      "mergetool \"meld\"" = {
        path = "${pkgs.meld}/bin/meld";
        cmd = "${pkgs.meld}/bin/meld --diff $BASE $LOCAL $REMOTE --output $MERGED";
        trustExitCode = false;
      };
    };

    programs.jujutsu.settings = lib.mkIf config.hdwlinux.programs.jujutsu.enable {
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

      ui = {
        diff-editor = "meld-3";
        merge-editor = "meld";
      };
    };
  };
}
