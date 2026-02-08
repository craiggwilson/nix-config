{
  config.substrate.modules.ai.agent = {
    tags = [
      "ai:agent"
    ];

    homeManager =
      {
        config,
        lib,
        ...
      }:
      let
        # Transform tagged union to the expected format (stdio servers only)
        mcpServers = lib.mapAttrs (
          name: server:
          if server ? stdio then
            {
              command = server.stdio.command;
              args = server.stdio.args;
            }
          else if server ? http then
            {
              url = server.http.url;
              headers = server.http.headers;
            }
          else
            throw "Unknown MCP server type for ${name}"
        ) config.hdwlinux.ai.agent.mcpServers;

      in
      {
        home.file = {
          ".ai/agent/mcp-servers.json".text = builtins.toJSON {
            inherit mcpServers;
          };
          ".ai/agent/agents".source = ./agents;
          ".ai/agent/commands".source = ./commands;
          ".ai/agent/rules".source = ./rules;
        }
        // (lib.mapAttrs' (
          n: v: lib.nameValuePair ".ai/agent/skills/${n}" { source = v; }
        ) config.hdwlinux.ai.skills);
      };
  };
}
