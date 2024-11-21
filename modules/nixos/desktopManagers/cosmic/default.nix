{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.cosmic;
in
{
  options.hdwlinux.desktopManagers.cosmic = {
    enable = lib.hdwlinux.mkEnableTagsOpt "cosmic" [ "desktop:cosmic" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;

    hdwlinux.nix.extra-substituters = {
      "https://cosmic.cachix.org/" = {
        key = "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=";
      };
    };
  };
}
