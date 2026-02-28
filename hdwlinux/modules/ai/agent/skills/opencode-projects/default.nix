{
  config.substrate.modules.ai.agent.skills.opencode-projects = {
    tags = [ "ai:agent" ];

    homeManager = _: {
      hdwlinux.ai.agent.skills.opencode-projects = ./skill;
    };
  };
}
