{
  config.substrate.modules.ai.agent.rules.mongodb-fiscal-calendar = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.rules.mongodb-fiscal-calendar = {
        description = "MongoDB fiscal year and quarter conventions used during planning.";
        content = ./content.md;
        extraMeta.type = "agent-requested";
      };
    };
  };
}
