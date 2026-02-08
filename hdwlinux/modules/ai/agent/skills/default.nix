{
  config.substrate.modules.ai.agent.skills = {
    tags = [
      "ai:agent"
    ];

    homeManager =
      { lib, ... }:
      {
        options.hdwlinux.ai.skills = lib.mkOption {
          description = "Skill definitions (directories containing multiple files).";
          type = lib.types.attrsOf lib.types.path;
          default = { };
        };
      };
  };
}
