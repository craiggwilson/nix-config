{
  config.substrate.modules.ai.agent.skills.distributed-systems-architect = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.distributed-systems-architect = ./skill;
    };
  };
}
