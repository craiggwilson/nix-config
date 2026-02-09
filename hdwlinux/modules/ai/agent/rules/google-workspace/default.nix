{
  config.substrate.modules.ai.agent.rules.google-workspace = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.rules.google-workspace = {
        metadata = {
          description = "Google Workspace access configuration";
          type = "agent-requested";
        };
        content = ./prompt.md;
      };
    };
  };
}
