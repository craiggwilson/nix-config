{
  config.substrate.modules.ai.agent.commands.planning-finalize = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.commands.planning-finalize = {
        metadata = {
          description = "Finalize and wrap up a planning cycle";
          argument-hint = "[optional-focus-area]";
        };
        content = ./prompt.md;
      };
    };
  };
}
