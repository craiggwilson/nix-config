{
  config.substrate.modules.programs = {
    provides = [ "core:interfaces" ];
    generic =
      { lib, ... }:
      {
        options.hdwlinux.programs.flatpaks = lib.mkOption {
          type = lib.types.listOf lib.types.anything;
          default = [ ];
        };
      };
  };
}
