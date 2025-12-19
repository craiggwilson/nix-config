{
  config.substrate.modules.security.sudo = {
    tags = [ "users:craig:personal" ];
    nixos = {
      security.sudo = {
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

