{
  config.substrate.modules.ai.agent.skills.test-master = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.test-master = ./skill;
    };
  };
}
