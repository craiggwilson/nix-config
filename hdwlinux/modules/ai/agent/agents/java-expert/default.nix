{
  config.substrate.modules.ai.agent.agents.java-expert = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.java-expert = {
        metadata = {
          name = "java-expert";
          description = "Expert Java developer with deep knowledge of the JVM ecosystem, enterprise patterns, and modern Java development. Masters Spring, build tools, testing, and performance optimization.";
          tools = "Read, Write, Edit, Glob, Grep, Bash";
          model = "opus4.5";
          color = "green";
        };
        content = ./prompt.md;
      };
    };
  };
}
