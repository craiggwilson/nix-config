{
  config.substrate.modules.ai.agent.rules.github = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.rules.github = {
        description = "GitHub access configuration";
        content = ./content.md;
        extraMeta.type = "agent_requested";
      };
    };
  };
}
