{
  config.substrate.modules.ai.agent.commands.planning-init = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.commands.planning-init = {
        metadata = {
          description = "Initialize a planning cycle for roadmap, project, or task planning";
          argument-hint = "[roadmap|project|task] [optional-focus-area]";
        };
        content = ./prompt.md;
      };
    };
  };
}
