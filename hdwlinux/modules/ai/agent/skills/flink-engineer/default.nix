{
  config.substrate.modules.ai.agent.skills.flink-engineer = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.flink-engineer = ./skill;
    };
  };
}
