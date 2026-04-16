{
  config.substrate.modules.ai.agent.commands = {
    tags = [ "ai:agent" ];

    homeManager =
      { lib, ... }:
      let
        # Command definitions without prompt paths (computed automatically)
        commands = {
          kb-add-to-inbox = {
            argumentHint = "[thought or content]";
            description = "Append a thought or fragment to the KB inbox";
          };

          kb-process-inbox = {
            argumentHint = "";
            description = "Synthesize KB inbox items into notes, enrich existing notes, update MOCs";
          };

          kb-research = {
            argumentHint = "[topic] [area]";
            description = "Research a topic and capture findings as atomic zettelkasten notes";
          };

          kb-start-project = {
            argumentHint = "[project-name]";
            description = "Create a new KB project with overview and progress files";
          };

          kb-work-on-project = {
            argumentHint = "[project]";
            description = "Start a working session on an active KB project";
          };

          kb-save-work-on-project = {
            argumentHint = "[project]";
            description = "Complete a KB project session — update progress, log session, commit";
          };

          kb-archive-project = {
            argumentHint = "[project]";
            description = "Archive a completed KB project — final progress, set status, move to archive";
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
