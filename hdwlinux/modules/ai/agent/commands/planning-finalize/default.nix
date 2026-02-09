{
  config.substrate.modules.ai.agent.commands.planning-finalize = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.commands.planning-finalize = {
        description = "Finalize and wrap up a planning cycle";
        content = ./content.md;
        extraMeta.argument-hint = "[optional-focus-area]";
      };
    };
  };
}
