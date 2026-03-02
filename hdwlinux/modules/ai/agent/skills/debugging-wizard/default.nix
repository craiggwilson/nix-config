{
  config.substrate.modules.ai.agent.skills.debugging-wizard = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.debugging-wizard = ./skill;
    };
  };
}
