{
  config.substrate.modules.ai.agent.commands.planning-init = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.commands.planning-init = {
        description = "Initialize a planning cycle for roadmap, project, or task planning";
        content = ./content.md;
        extraMeta.augment.argument-hint = "[roadmap|project|task] [optional-focus-area]";
      };
    };
  };
}
