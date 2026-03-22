{
  config.substrate.modules.ai.agent.skills.kb = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.kb = ./skill;
    };
  };
}
