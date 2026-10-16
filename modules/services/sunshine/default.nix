{
  config.substrate.modules.services.sunshine = {
    # Dormant by name: roots require bare gaming (which must NOT sweep
    # sunshine in), so this stays hyphen-flat and reachable only by
    # explicit requirement.
    provides = [ "gaming-streaming" ];
    tags = [ "gaming:streaming" ];
    nixos = {
      services.sunshine = {
        enable = true;
        autoStart = false;
        capSysAdmin = true;
        openFirewall = true;
      };
    };
  };
}
