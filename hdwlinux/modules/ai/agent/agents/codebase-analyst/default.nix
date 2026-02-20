{
  config.substrate.modules.ai.agent.agents.codebase-analyst = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.codebase-analyst = {
        description = "Expert codebase analyst specializing in code archaeology, architecture discovery, and technical research. Masters code navigation, dependency analysis, and pattern recognition to provide deep insights into any codebase.";
        model = "explore";
        content = ./content.md;
        extraMeta.augment.color = "teal";
      };
    };
  };
}
