{
  config.substrate.modules.ai.agent.skills.observability-engineer = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.observability-engineer = ./skill;
    };
  };
}
