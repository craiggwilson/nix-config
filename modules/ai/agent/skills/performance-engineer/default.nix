{
  config.substrate.modules.ai.agent.skills.performance-engineer = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.performance-engineer = ./skill;
    };
  };
}
