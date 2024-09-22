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
  cfg = config.hdwlinux.features.midivisualizer;
in
{
  options.hdwlinux.features.midivisualizer = with types; {
    enable = mkEnableOpt [
      "audio:midi"
      "gui"
    ] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [ MIDIVisualizer ];
}
