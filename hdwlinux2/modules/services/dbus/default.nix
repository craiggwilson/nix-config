{
  config.substrate.modules.services.dbus = {
    nixos = {
      services.dbus = {
        enable = true;
        implementation = "broker";
      };
    };
  };
}

