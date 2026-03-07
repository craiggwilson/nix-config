{
  config.substrate.modules.ai.agent.skills.mongodb-specialist = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.mongodb-specialist = ./skill;
    };
  };
}
