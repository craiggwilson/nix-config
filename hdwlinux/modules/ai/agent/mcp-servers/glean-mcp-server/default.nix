{
  config.substrate.modules.ai.agent.mcp-servers.glean = {
    tags = [
      "users:craig:work"
      "programming"
      "ai:mcp"
    ];
    homeManager = {
      hdwlinux.ai.agent.mcpServers.glean.http = {
        url = "https://mongodb-be.glean.com/mcp/default";
      };
    };
  };
}
