{
  config.substrate.modules.ai.agent.commands.planning-codebase-map = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.commands.planning-codebase-map = {
        description = "Map and document a codebase as part of planning discovery";
        content = ./content.md;
        extraMeta.augment.argument-hint = "[repository-name-or-focus]";
      };
    };
  };
}
