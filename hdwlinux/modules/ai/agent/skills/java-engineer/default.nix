{
  config.substrate.modules.ai.agent.skills.java-engineer = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.java-engineer = ./skill;
    };
  };
}
