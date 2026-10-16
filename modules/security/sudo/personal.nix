{
  config.substrate.modules.security.sudo.personal = {
    # These configs were never active under tags (the merged sudo node
    # AND'd both user tags, matching no host). Deliberately activating:
    # core:security is a host requirement; the profile gate scopes which
    # variant loads.
    provides = [ "security:sudo:personal" "core:security" ];
    requires = [ "profiles:personal" ];

    tags = [ "users:craig:personal" ];
    nixos = {
      security.sudo.enable = false;
      security.sudo-rs = {
        enable = true;
        execWheelOnly = true;
        wheelNeedsPassword = false;

        extraConfig = ''
          Defaults timestamp_timeout=5
          Defaults timestamp_type=global
          Defaults passwd_tries=3
          Defaults passwd_timeout=0
        '';
      };
    };
  };
}
