{
  config.substrate.modules.ai.agent.agents.go-expert = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.go-expert = {
        description = "Expert Go developer with deep knowledge of idiomatic Go, concurrency patterns, and cloud-native development. Masters the standard library, popular frameworks, and performance optimization.";
        model = "opus4.5";
        content = ./content.md;
        extraMeta.color = "cyan";
      };
    };
  };
}
