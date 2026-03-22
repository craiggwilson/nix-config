{
  config.substrate.modules.ai.agent.commands = {
    tags = [ "ai:agent" ];

    homeManager =
      { lib, ... }:
      let
        # Command definitions without prompt paths (computed automatically)
        commands = {
          session = {
            argumentHint = "[project]";
            description = "Start a KB project session from anywhere — reads progress, does work, updates state";
            prompt = ./prompts/session.md;
          };

          research = {
            argumentHint = "[topic] [area]";
            description = "Conduct research and capture findings in the KB";
            prompt = ./prompts/research.md;
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
