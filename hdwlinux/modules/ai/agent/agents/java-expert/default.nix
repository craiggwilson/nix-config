{
  config.substrate.modules.ai.agent.agents.java-expert = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.java-expert = {
        description = "Expert Java developer with deep knowledge of the JVM ecosystem, enterprise patterns, and modern Java development. Masters Spring, build tools, testing, and performance optimization.";
        model = "opus4.5";
        content = ./content.md;
        extraMeta.color = "green";
      };
    };
  };
}
