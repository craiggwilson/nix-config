{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.features.dconf;
in
{
  options.hdwlinux.features.dconf = {
    enable = lib.hdwlinux.mkBoolOpt true "Enable dconf feature.";
  };

  config = lib.mkIf cfg.enable { programs.dconf.enable = true; };
}
