{
  config.substrate.modules.services.dbus = {
    provides = [ "core:session" ];

    nixos = {
      services.dbus = {
        enable = true;
        implementation = "broker";
      };
    };
  };
}
