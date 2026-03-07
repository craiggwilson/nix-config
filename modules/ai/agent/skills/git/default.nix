{
  config.substrate.modules.ai.agent.skills.git = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.git = ./skill;
    };
  };
}
