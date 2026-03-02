{
  config.substrate.modules.ai.agent.skills.rust-engineer = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.rust-engineer = ./skill;
    };
  };
}
