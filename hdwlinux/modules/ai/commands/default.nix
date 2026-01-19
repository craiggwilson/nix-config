{
  config.substrate.modules.ai.commands = {
    generic =
      { lib, ... }:
      {
        options.hdwlinux.ai.commands = lib.mkOption {
          description = "Command definitions.";
          type = lib.types.attrsOf lib.types.lines;
          default = { };
        };

        config.hdwlinux.ai.commands = {
        };
      };
  };
}
