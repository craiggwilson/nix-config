{
  config.substrate.modules.ai.agent.skills.kubernetes-specialist = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.kubernetes-specialist = ./skill;
    };
  };
}
