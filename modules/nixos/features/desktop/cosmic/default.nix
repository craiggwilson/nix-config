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
  cfg = config.hdwlinux.features.desktop.cosmic;
in
{
  options.hdwlinux.features.desktop.cosmic = with types; {
    enable = mkEnableOpt [ "desktop:cosmic" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;

    hdwlinux.nix.extra-substituters = {
      "https://cosmic.cachix.org/" = {
        key = "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=";
      };
    };
  };
}
