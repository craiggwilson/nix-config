{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.delta;
in
{
  options.hdwlinux.programs.delta = {
    enable = lib.hdwlinux.mkEnableOption "delta" true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.delta ];

    programs.git.settings = lib.mkIf config.hdwlinux.programs.git.enable {
      core.pager = "delta";
      delta = {
        line-numbers = true;
        navigate = true;
        side-by-side = true;
      };
      interactive.diffFilter = "delta --color-only";
    };

    programs.jujutsu.settings = lib.mkIf config.hdwlinux.programs.jujutsu.enable {
      ui = {
        pager = "${pkgs.delta}/bin/delta";
      };
    };
  };
}
