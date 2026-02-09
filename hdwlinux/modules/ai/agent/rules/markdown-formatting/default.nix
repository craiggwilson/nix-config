{
  config.substrate.modules.ai.agent.rules.markdown-formatting = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.rules.markdown-formatting = {
        metadata = {
          description = "Markdown formatting standards for all generated documents";
          type = "always_apply";
        };
        content = ./prompt.md;
      };
    };
  };
}
