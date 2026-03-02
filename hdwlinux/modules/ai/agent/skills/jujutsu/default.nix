{
  config.substrate.modules.ai.agent.skills.jujutsu = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.jujutsu = ./skill;
    };
  };
}
