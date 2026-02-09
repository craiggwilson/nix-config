{
  config.substrate.modules.ai.agent.commands.planning-codebase-map = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.commands.planning-codebase-map = {
        metadata = {
          description = "Map and document a codebase as part of planning discovery";
          argument-hint = "[repository-name-or-focus]";
        };
        content = ./prompt.md;
      };
    };
  };
}
