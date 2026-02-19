{
  config.substrate.modules.ai.agent.rules.google-workspace = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.rules.google-workspace = {
        description = "Google Workspace access configuration";
        content = ./content.md;
        extraMeta.augment.type = "agent-requested";
      };
    };
  };
}
