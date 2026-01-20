{
  config.substrate.modules.ai.mcp-servers = {
    tags = [
      "users:craig:work"
      "programming"
      "ai:mcp"
    ];
    generic = {
      hdwlinux.ai.mcpServers.glean.http = {
        url = "https://mongodb-be.glean.com/mcp/default";
      };
    };
  };
}
