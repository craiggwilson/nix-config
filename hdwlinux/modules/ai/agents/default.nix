{
  config.substrate.modules.ai.agents = {
    generic =
      { lib, ... }:
      {
        options.hdwlinux.ai.agents = lib.mkOption {
          description = "Agent definitions.";
          type = lib.types.attrsOf lib.types.lines;
          default = { };
        };

        config.hdwlinux.ai.agents = {
          #distributed-systems-architect = builtins.readFile ./distributed-systems-architect.md;
        };
      };
  };
}
