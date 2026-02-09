{
  # Base module that defines all AI agent options
  config.substrate.modules.ai.agent.options = {
    homeManager =
      { lib, ... }:
      let
        # Common type for agents, commands, and rules
        # Each has flexible metadata (attrsOf str) and content (path)
        itemType = lib.types.submodule {
          options = {
            metadata = lib.mkOption {
              description = "Flexible key-value metadata. Each coding agent interprets relevant keys.";
              type = lib.types.attrsOf lib.types.str;
              default = { };
            };
            content = lib.mkOption {
              description = "Path to the markdown file containing the content.";
              type = lib.types.path;
            };
          };
        };

        # MCP server type - tagged union for stdio or http servers
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
        options.hdwlinux.ai.agent = {
          agents = lib.mkOption {
            description = "Agent (subagent) definitions for AI assistants.";
            type = lib.types.attrsOf itemType;
            default = { };
          };

          commands = lib.mkOption {
            description = "Command definitions for AI assistants.";
            type = lib.types.attrsOf itemType;
            default = { };
          };

          mcpServers = lib.mkOption {
            description = "MCP servers to configure for AI assistants.";
            type = lib.types.attrsOf mcpServerType;
            default = { };
          };

          rules = lib.mkOption {
            description = "Rule definitions for AI assistants.";
            type = lib.types.attrsOf itemType;
            default = { };
          };

          skills = lib.mkOption {
            description = "Skill definitions (directories containing multiple files).";
            type = lib.types.attrsOf lib.types.path;
            default = { };
          };
        };
      };
  };
}
