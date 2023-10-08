{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.swaylock;
in
{
  options.hdwlinux.packages.swaylock = with types; {
    enable = mkBoolOpt false "Whether or not to enable swaylock.";
    settings = mkOpt attrs { } (mdDoc "Options passed directly to home-manager's `programs.swaylock.settings`.");
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.swaylock = {
      enable = true;
      settings = mkAliasDefinitions options.hdwlinux.packages.swaylock.settings;
    };

    security.pam.services.swaylock = { }; # "auth include login";
  };
}
