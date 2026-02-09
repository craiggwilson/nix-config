{
  config.substrate.modules.ai.agent.rules.mongodb-fiscal-calendar = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.rules.mongodb-fiscal-calendar = {
        metadata = {
          description = "MongoDB fiscal year and quarter conventions used during planning.";
          type = "agent-requested";
        };
        content = ./prompt.md;
      };
    };
  };
}
