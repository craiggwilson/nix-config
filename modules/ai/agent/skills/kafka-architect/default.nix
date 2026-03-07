{
  config.substrate.modules.ai.agent.skills.kafka-architect = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.kafka-architect = ./skill;
    };
  };
}
