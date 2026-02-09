{
  config.substrate.modules.ai.agent.commands.planning-research = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.commands.planning-research = {
        metadata = {
          description = "Conduct focused research as part of planning discovery";
          argument-hint = "[research-topic]";
        };
        content = ./prompt.md;
      };
    };
  };
}
