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

          kb-add-to-inbox = {
            argumentHint = "[thought or content]";
            description = "Append a thought or fragment to the KB inbox";
            prompt = ./prompts/kb-add-to-inbox.md;
          };

          kb-process-inbox = {
            argumentHint = "";
            description = "Synthesize KB inbox items into notes, enrich existing notes, update MOCs";
            prompt = ./prompts/kb-process-inbox.md;
          };

          kb-research = {
            argumentHint = "[topic] [area]";
            description = "Research a topic and capture findings as atomic zettelkasten notes";
            prompt = ./prompts/kb-research.md;
          };

          kb-start-project = {
            argumentHint = "[project-name]";
            description = "Create a new KB project with overview and progress files";
            prompt = ./prompts/kb-start-project.md;
          };

          kb-continue-project = {
            argumentHint = "[project]";
            description = "Continue an active KB project — read state, do work, update progress, log session";
            prompt = ./prompts/kb-continue-project.md;
          };

          kb-complete-project = {
            argumentHint = "[project]";
            description = "Wrap up a completed KB project — archive state and final session";
            prompt = ./prompts/kb-complete-project.md;
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
