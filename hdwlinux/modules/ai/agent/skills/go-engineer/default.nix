{
  config.substrate.modules.ai.agent.skills.go-engineer = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.go-engineer = ./skill;
    };
  };
}
