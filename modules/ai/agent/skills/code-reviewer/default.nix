{
  config.substrate.modules.ai.agent.skills.code-reviewer = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.skills.code-reviewer = ./skill;
    };
  };
}
