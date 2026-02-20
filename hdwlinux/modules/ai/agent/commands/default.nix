{
  config.substrate.modules.ai.agent.commands = {
    tags = [ "ai:agent" ];

    homeManager =
      { lib, ... }:
      let
        # Command definitions without prompt paths (computed automatically)
        commands = {
          planning-codebase-map = {
            description = "Map and document a codebase as part of planning discovery";
            extraMeta.augment.argument-hint = "[repository-name-or-focus]";
          };

          planning-continue = {
            description = "Continue an in-progress planning cycle";
            extraMeta.augment.argument-hint = "[optional-focus-area]";
          };

          planning-finalize = {
            description = "Finalize and wrap up a planning cycle";
            extraMeta.augment.argument-hint = "[optional-focus-area]";
          };

          planning-init = {
            description = "Initialize a planning cycle for roadmap, project, or task planning";
            extraMeta.augment.argument-hint = "[roadmap|project|task] [optional-focus-area]";
          };

          planning-research = {
            description = "Conduct focused research as part of planning discovery";
            extraMeta.augment.argument-hint = "[research-topic]";
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
