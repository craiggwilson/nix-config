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
  cfg = config.hdwlinux.features.nasc;
in
{
  options.hdwlinux.features.nasc = with types; {
    enable = mkEnableOpt [ "gui" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ nasc ];

    home.shellAliases = {
      nasc = "com.github.parnold_x.nasc";
    };
  };
}
