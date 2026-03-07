{
  config.substrate.modules.ai.agent.skills.database-architect = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.database-architect = ./skill;
    };
  };
}
