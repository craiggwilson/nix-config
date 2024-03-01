{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.chromium;
in
{
  options.hdwlinux.features.chromium = with types; {
    enable = mkEnableOpt ["gui" "gaming"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    programs.chromium.enable = true;
  };
}
