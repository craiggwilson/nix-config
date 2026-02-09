{
  config.substrate.modules.ai.agent.agents.flink-expert = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.flink-expert = {
        metadata = {
          name = "flink-expert";
          description = "Expert Apache Flink architect with deep knowledge of stream processing, stateful computations, event-time processing, and production deployments. Masters DataStream API, Table API, SQL, state management, and operational excellence.";
          tools = "Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch";
          model = "opus4.5";
          color = "purple";
        };
        content = ./prompt.md;
      };
    };
  };
}
