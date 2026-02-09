{
  config.substrate.modules.ai.agent.agents.kafka-expert = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.kafka-expert = {
        metadata = {
          name = "kafka-expert";
          description = "Expert Apache Kafka and WarpStream architect with deep knowledge of event streaming, topic design, performance tuning, and cloud-native deployments. Masters producers, consumers, Kafka Streams, Connect, and WarpStream's S3-native architecture.";
          tools = "Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch";
          model = "opus4.5";
          color = "blue";
        };
        content = ./prompt.md;
      };
    };
  };
}
