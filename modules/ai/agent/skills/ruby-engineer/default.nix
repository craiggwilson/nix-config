{
  config.substrate.modules.ai.agent.skills.ruby-engineer = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.ruby-engineer = ./skill;
    };
  };
}
