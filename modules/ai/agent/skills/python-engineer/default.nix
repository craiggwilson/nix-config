{
  config.substrate.modules.ai.agent.skills.python-engineer = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.python-engineer = ./skill;
    };
  };
}
