{
  config.substrate.modules.ai.agent.agents.codebase-analyst = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.codebase-analyst = {
        metadata = {
          name = "codebase-analyst";
          description = "Expert codebase analyst specializing in code archaeology, architecture discovery, and technical research. Masters code navigation, dependency analysis, and pattern recognition to provide deep insights into any codebase.";
          tools = "Read, Edit, Glob, Grep, Bash, WebFetch, WebSearch";
          model = "opus4.5";
          color = "teal";
        };
        content = ./prompt.md;
      };
    };
  };
}
