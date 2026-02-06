{
  # Base module that defines the mcpServers option
  # Uses a unique path to avoid tag conflicts with individual MCP server modules
  config.substrate.modules.ai.agent._mcp-servers-base = {
    homeManager =
      { lib, ... }:
      let
        mcpServerType = lib.types.attrTag {
          stdio = lib.mkOption {
            description = "A stdio-based MCP server that communicates via stdin/stdout.";
            type = lib.types.submodule {
              options = {
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
          };
          http = lib.mkOption {
            description = "An HTTP-based MCP server that communicates over HTTP.";
            type = lib.types.submodule {
              options = {
                url = lib.mkOption {
                  description = "The URL of the MCP server.";
                  type = lib.types.str;
                };
                headers = lib.mkOption {
                  description = "HTTP headers to include in requests.";
                  type = lib.types.attrsOf lib.types.str;
                  default = { };
                };
              };
            };
          };
        };

      in
      {
        options.hdwlinux.ai.agent.mcpServers = lib.mkOption {
          description = "MCP servers to configure for AI assistants.";
          type = lib.types.attrsOf mcpServerType;
          default = { };
        };
      };
  };
}
