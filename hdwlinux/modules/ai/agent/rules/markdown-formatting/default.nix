{
  config.substrate.modules.ai.agent.rules.markdown-formatting = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.rules.markdown-formatting = {
        description = "Markdown formatting standards for all generated documents";
        content = ./content.md;
        extraMeta.augment.type = "always_apply";
      };
    };
  };
}
