{
  config.substrate.modules.services.sunshine = {
    tags = [ "service:gaming-streaming" ];
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
