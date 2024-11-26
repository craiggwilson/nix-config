{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.midivisualizer;
in
{
  options.hdwlinux.programs.midivisualizer = {
    enable = config.lib.hdwlinux.mkEnableOption "midivisualizer" [
      "audio:midi"
      "gui"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.MIDIVisualizer ];
  };
}
