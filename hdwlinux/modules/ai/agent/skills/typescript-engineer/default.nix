{
  config.substrate.modules.ai.agent.skills.typescript-engineer = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.typescript-engineer = ./skill;
    };
  };
}
