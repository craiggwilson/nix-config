{
  config.substrate.modules.ai.mcp-servers = {
    generic =
      { lib, ... }:
      let
        mcpServerType = lib.types.submodule {
          options = {
            type = lib.mkOption {
              description = "The transport type for the MCP server.";
              type = lib.types.enum [
                "stdio"
                "http"
                "sse"
              ];
              default = "stdio";
            };
            command = lib.mkOption {
              description = "The command to run.";
              type = lib.types.str;
            };
            args = lib.mkOption {
              description = "The arguments to pass to the command.";
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          };
        };

      in
      {
        options.hdwlinux.ai.mcpServers = lib.mkOption {
          description = "MCP servers to configure for AI assistants.";
          type = lib.types.attrsOf mcpServerType;
          default = { };
        };
      };
  };
}
