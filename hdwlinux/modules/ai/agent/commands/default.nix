{
  config.substrate.modules.ai.agent.commands = {
    tags = [ "ai:agent" ];

    homeManager =
      { lib, ... }:
      let
        # Command definitions without prompt paths (computed automatically)
        commands = {
          planning-codebase-map = {
            argumentHint = "[repository-name-or-focus]";
            description = "Map and document a codebase as part of planning discovery";
          };

          planning-continue = {
            argumentHint = "[optional-focus-area]";
            description = "Continue an in-progress planning cycle";
          };

          planning-finalize = {
            argumentHint = "[optional-focus-area]";
            description = "Finalize and wrap up a planning cycle";
          };

          planning-init = {
            argumentHint = "[roadmap|project|task] [optional-focus-area]";
            description = "Initialize a planning cycle for roadmap, project, or task planning";
          };

          planning-research = {
            argumentHint = "[research-topic]";
            description = "Conduct focused research as part of planning discovery";
          };
        };

        # Add prompt path to each command based on its name
        addPromptPath =
          name: command: command // { prompt = command.prompt or (./prompts + "/${name}.md"); };
      in
      {
        hdwlinux.ai.agent.commands = lib.mapAttrs addPromptPath commands;
      };
  };
}
