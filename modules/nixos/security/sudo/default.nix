{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.security.sudo;
in
{
  options.hdwlinux.security.sudo = {
    enablePasswordlessSudo = config.lib.hdwlinux.mkEnableOption "sudo" "personal";

    timeout = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = ''
        Timeout in minutes for sudo password caching.
        After this period, sudo will require password re-entry.
        Set to 0 to require password for every sudo command.
      '';
    };
  };

  config = {
    security.sudo = {
      execWheelOnly = true;
      wheelNeedsPassword = !cfg.enablePasswordlessSudo;

      # Configure sudo timeout for better security
      # This applies even when passwordless sudo is disabled
      extraConfig = ''
        # Set the sudo password timeout (in minutes)
        # Default is 5 minutes, can be configured via hdwlinux.security.sudo.timeout
        Defaults timestamp_timeout=${toString cfg.timeout}

        # Reset timestamp on failed authentication attempts for security
        Defaults timestamp_type=global

        # Require password for privilege escalation operations
        Defaults passwd_tries=3
        Defaults passwd_timeout=0
      '';
    };
  };
}
