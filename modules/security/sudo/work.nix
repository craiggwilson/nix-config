{
  config.substrate.modules.security.sudo.work = {
    # See personal.nix for the activation note.
    provides = [
      "security:sudo:work"
      "core:security"
    ];
    requires = [ "profiles:work" ];
    nixos = {
      security.sudo.enable = false;
      security.sudo-rs = {
        enable = true;
        execWheelOnly = true;
        wheelNeedsPassword = true;

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
