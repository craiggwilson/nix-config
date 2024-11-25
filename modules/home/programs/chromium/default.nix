{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs.chromium;
in
{
  options.hdwlinux.programs.chromium = {
    enable = config.lib.hdwlinux.mkEnableAllOption "chromium" [
      "gui"
      "gaming"
    ];
  };

  config = lib.mkIf cfg.enable {
    programs.chromium.enable = true;
  };
}
