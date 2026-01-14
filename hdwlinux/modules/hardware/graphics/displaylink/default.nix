{
  config.substrate.modules.hardware.graphics.displaylink = {
    nixos =
      { config, lib, ... }:
      let
        needsDisplaylink = builtins.any (m: m.displaylink or false) (
          builtins.attrValues config.hdwlinux.hardware.monitors
        );
      in
      {
        services.xserver.videoDrivers = lib.mkIf needsDisplaylink [ "displaylink" ];
      };
  };
}
