{
  config.substrate.modules.ai.agent.skills.engram = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.engram = ./skill;
    };
  };
}
