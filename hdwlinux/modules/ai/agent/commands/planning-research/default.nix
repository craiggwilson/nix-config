{
  config.substrate.modules.ai.agent.commands.planning-research = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.commands.planning-research = {
        description = "Conduct focused research as part of planning discovery";
        content = ./content.md;
        extraMeta.argument-hint = "[research-topic]";
      };
    };
  };
}
