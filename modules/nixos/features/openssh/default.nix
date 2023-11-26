{ options, config, pkgs, lib, host ? "", format ? "", inputs ? { }, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.openssh;
in
{
  options.hdwlinux.features.openssh = with types; {
    enable = mkBoolOpt false "Whether or not to configure OpenSSH support.";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      
      # Require public key authentication
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };
  };
}
