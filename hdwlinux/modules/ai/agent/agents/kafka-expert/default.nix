{
  config.substrate.modules.ai.agent.agents.kafka-expert = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.kafka-expert = {
        description = "Expert Apache Kafka and WarpStream architect with deep knowledge of event streaming, topic design, performance tuning, and cloud-native deployments. Masters producers, consumers, Kafka Streams, Connect, and WarpStream's S3-native architecture.";
        model = "reasoning";
        content = ./content.md;
        extraMeta.augment.color = "blue";
      };
    };
  };
}
