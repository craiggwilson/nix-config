{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features._1password;
in
{
  options.hdwlinux.features._1password = with types; {
    enable = mkBoolOpt false "Whether or not to enable 1password.";
    enableGui = mkBoolOpt true "Whether or not to enable the GUI."; # TODO: see if there is a way to default this if graphics are enabled...
  };

  config.hdwlinux.user.extraGroups = mkIf cfg.enable [ "1password-cli" ];

  config.programs._1password.enable = mkIf cfg.enable true;

  config.programs._1password-gui = mkIf (cfg.enable && cfg.enableGui) {
    enable = true;
    polkitPolicyOwners = [ config.hdwlinux.user.name ];
  };
}
