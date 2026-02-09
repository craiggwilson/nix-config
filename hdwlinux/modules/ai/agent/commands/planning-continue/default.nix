{
  config.substrate.modules.ai.agent.commands.planning-continue = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.commands.planning-continue = {
        metadata = {
          description = "Continue an in-progress planning cycle";
          argument-hint = "[optional-focus-area]";
        };
        content = ./prompt.md;
      };
    };
  };
}
