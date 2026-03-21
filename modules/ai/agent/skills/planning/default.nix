{
  config.substrate.modules.ai.agent.skills.planning = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.planning = ./skill;
    };
  };
}
