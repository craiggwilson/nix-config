{
  config.substrate.modules.ai.agent.rules.github = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.rules.github = {
        metadata = {
          description = "GitHub access configuration";
          type = "agent_requested";
        };
        content = ./prompt.md;
      };
    };
  };
}
