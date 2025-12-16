{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.gh;
in
{
  options.hdwlinux.programs.gh = {
    enable = config.lib.hdwlinux.mkEnableOption "gh" "programming";
  };

  config = lib.mkIf cfg.enable {
    programs.gh = {
      enable = true;
    };
    programs.gh-dash = {
      enable = true;
    };

    hdwlinux.programs.git.aliases = {
      pr-create = "!${pkgs.gh}/bin/gh pr create --web --fill";
      pr-view = "!${pkgs.gh}/bin/gh pr view --web";
    };
  };
}
