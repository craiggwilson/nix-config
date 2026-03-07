{
  config.substrate.modules.ai.agent.skills.aws-architect = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.aws-architect = ./skill;
    };
  };
}
