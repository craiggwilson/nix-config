{
  config.substrate.modules.ai.agent.commands.planning-continue = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.commands.planning-continue = {
        description = "Continue an in-progress planning cycle";
        content = ./content.md;
        extraMeta.argument-hint = "[optional-focus-area]";
      };
    };
  };
}
