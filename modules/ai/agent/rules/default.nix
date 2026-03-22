{
  config.substrate.modules.ai.agent.rules = {
    tags = [ "ai:agent" ];

    homeManager =
      { lib, ... }:
      let
        # Rule definitions without prompt paths (computed automatically)
        rules = {
          coding-practices = {
            description = "Personal coding practices and style guidelines";
            loadMode = "auto";
          };

          github = {
            description = "GitHub access configuration";
            loadMode = "auto";
          };

          google-workspace = {
            description = "Google Workspace access configuration";
            loadMode = "auto";
          };

          jujutsu = {
            description = "Version control using Jujutsu (jj)";
            loadMode = "always";
          };

          markdown-formatting = {
            description = "Markdown formatting standards for all generated documents";
            loadMode = "auto";
          };

          mongodb-fiscal-calendar = {
            description = "MongoDB fiscal year and quarter conventions used during planning.";
            loadMode = "auto";
          };

          obsidian = {
            description = "Obsidian knowledge base location and usage for research, planning, and ideas";
            loadMode = "always";
          };
        };

        # Add prompt path to each rule based on its name
        addPromptPath = name: rule: rule // { prompt = rule.prompt or (./prompts + "/${name}.md"); };
      in
      {
        hdwlinux.ai.agent.rules = lib.mapAttrs addPromptPath rules;
      };
  };
}
