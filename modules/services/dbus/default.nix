{
  config.substrate.modules.services.dbus = {
    tags = [ "core:base" ];
    nixos = {
      services.dbus = {
        enable = true;
        implementation = "broker";
      };
    };
  };
}
