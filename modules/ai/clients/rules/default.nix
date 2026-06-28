{
  config.substrate.modules.ai.clients.rules = {
    tags = [ "ai:clients" ];

    homeManager =
      { lib, ... }:
      let
        # Rule definitions without prompt paths (computed automatically)
        rules = {
          coding-practices = {
            description = "Personal coding practices and style guidelines";
            loadMode = "auto";
          };

          jujutsu = {
            description = "Version control using Jujutsu (jj)";
            loadMode = "always";
          };

          obsidian = {
            description = "Obsidian knowledge base location and usage for research, planning, and ideas";
            loadMode = "always";
          };

          ponytail = {
            description = "Lazy senior dev mode: YAGNI, stdlib first, shortest working diff";
            loadMode = "always";
          };
        };

        # Add prompt path to each rule based on its name
        addPromptPath = name: rule: rule // { prompt = rule.prompt or (./prompts + "/${name}.md"); };
      in
      {
        hdwlinux.ai.clients.rules = lib.mapAttrs addPromptPath rules;
      };
  };
}
