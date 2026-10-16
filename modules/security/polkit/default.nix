{
  config.substrate.modules.security.polkit = {
    provides = [ "security:polkit" "core:session" ];

    nixos = {
      security.polkit.enable = true;
    };
  };
}
