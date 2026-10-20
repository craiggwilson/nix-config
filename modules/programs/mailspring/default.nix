{
  config.substrate.modules.programs.mailspring = {
    tags = [
      "desktop"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.mailspring ];

        secretspec.entries.MAILSPRING_BEARER_TOKEN = {
          description = "Bearer token for Mailspring's local MCP server.";
          ref = {
            vault = "Craig";
            item = "Mailspring";
            field = "bearer_token";
          };
        };
      };
  };

  # Mailspring serves MCP itself, on loopback, when its MCP Server preference is
  # enabled. Declared here rather than under ai/clients/mcp-servers so that
  # everything about Mailspring lives in one module.
  config.substrate.modules.programs.mailspring.mcp = {
    tags = [
      "ai:clients"
      "desktop"
    ];

    homeManager = {
      hdwlinux.ai.clients.mcpServers.mailspring.http = {
        url = "http://127.0.0.1:2587/mcp";

        # Mailspring mints this token itself and shows it in its MCP Server
        # preferences tab. The registry records only that the header needs a
        # secret; each client below decides how to supply it.
        headers.Authorization = {
          secret = "MAILSPRING_BEARER_TOKEN";
          prefix = "Bearer ";
        };
      };
    };
  };
}
