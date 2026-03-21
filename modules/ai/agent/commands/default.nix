{
  config.substrate.modules.ai.agent.commands = {
    tags = [ "ai:agent" ];

    homeManager =
      { lib, ... }:
      let
        # Command definitions without prompt paths (computed automatically)
        commands = {
          planning = {
            argumentHint = "[focus-area]";
            description = "State management framework for maintaining consistency across planning sessions";
            prompt = ./prompts/planning.md;
          };
        };

        # Add prompt path to each command based on its name (if not already set)
        addPromptPath =
          name: command: command // { prompt = command.prompt or (./prompts + "/${name}.md"); };
      in
      {
        hdwlinux.ai.agent.commands = lib.mapAttrs addPromptPath commands;
      };
  };
}
