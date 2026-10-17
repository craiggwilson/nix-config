{
  config.substrate.modules.services.dbus = {
    provides = [
      "services:dbus"
      "core:session"
    ];

    nixos = {
      services.dbus = {
        enable = true;
        implementation = "broker";
      };
    };
  };
}
