{
  config.substrate.modules.security.sudo.personal = {
    tags = [ "profile:personal" ];
    nixos = {
      security.sudo.enable = false;
      security.sudo-rs = {
        enable = true;
        execWheelOnly = true;
        wheelNeedsPassword = true;

        extraConfig = ''
          Defaults timestamp_timeout=5
          Defaults passwd_tries=3
          Defaults passwd_timeout=0
        '';
      };
    };
  };
}
