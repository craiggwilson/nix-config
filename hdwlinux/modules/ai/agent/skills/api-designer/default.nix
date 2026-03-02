{
  config.substrate.modules.ai.agent.skills.api-designer = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.api-designer = ./skill;
    };
  };
}
