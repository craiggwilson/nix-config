{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.manix;
in
{
  options.hdwlinux.programs.manix = {
    enable = lib.hdwlinux.mkEnableOption "manix" true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
        name = "manix";
        runtimeInputs = [
          pkgs.manix
          pkgs.fzf
        ];
        subcommands = {
          "*" = "manix \"$@\"";
          options = ''
            search="$1"
            shift
            manix "$search" | grep '^# ' | sed 's/^# \(.*\) (.*/\1/;s/ (.*//;s/^# //' | fzf --preview="manix '{}'" | xargs manix
          '';
        };
      })
    ];
  };
}
