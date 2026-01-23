{
  config.substrate.modules.ai.mcp-servers = {
    tags = [
      "users:craig:work"
      "programming"
      "ai:mcp"
    ];
    homeManager = {
      hdwlinux.ai.mcpServers.glean.http = {
        url = "https://mongodb-be.glean.com/mcp/default";
      };
    };
  };
}
