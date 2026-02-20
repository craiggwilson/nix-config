{
  config.substrate.modules.ai.agent.rules = {
    tags = [ "ai:agent" ];

    homeManager =
      { lib, ... }:
      let
        # Rule definitions without prompt paths (computed automatically)
        rules = {
          github = {
            description = "GitHub access configuration";
            extraMeta.augment.type = "agent_requested";
          };

          google-workspace = {
            description = "Google Workspace access configuration";
            extraMeta.augment.type = "agent-requested";
          };

          jujutsu = {
            description = "Version control using Jujutsu (jj)";
            extraMeta.augment.type = "always_apply";
          };

          markdown-formatting = {
            description = "Markdown formatting standards for all generated documents";
            extraMeta.augment.type = "always_apply";
          };

          mongodb-fiscal-calendar = {
            description = "MongoDB fiscal year and quarter conventions used during planning.";
            extraMeta.augment.type = "agent-requested";
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
