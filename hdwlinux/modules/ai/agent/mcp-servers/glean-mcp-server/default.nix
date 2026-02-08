{
  config.substrate.modules.ai.agent.mcp-servers.glean = {
    tags = [
      "ai:agent"
      "users:craig:work"
    ];
    homeManager = {
      hdwlinux.ai.agent.mcpServers.glean.http = {
        url = "https://mongodb-be.glean.com/mcp/default";
      };
    };
  };
}
