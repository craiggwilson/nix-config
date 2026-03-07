{
  config.substrate.modules.programs = {
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
