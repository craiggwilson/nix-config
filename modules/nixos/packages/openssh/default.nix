{ options, config, pkgs, lib, host ? "", format ? "", inputs ? { }, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.packages.openssh;
in
{
  options.hdwlinux.packages.openssh = with types; {
    enable = mkBoolOpt false "Whether or not to configure OpenSSH support.";
    authorizedKeys = mkOpt (listOf str) [ ] "The public keys to authorize for use.";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      # Require public key authentication
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };

    hdwlinux.user.extraOptions.openssh.authorizedKeys.keys = mkAliasDefinitions options.hdwlinux.packages.openssh.authorizedKeys;
  };
}