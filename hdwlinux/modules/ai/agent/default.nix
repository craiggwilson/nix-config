{
  config.substrate.modules.ai.agent.options = {
    tags = [
      "ai:agent"
    ];
    homeManager =
      { lib, ... }:
      let
        toolPermission = lib.types.enum [
          "allow"
          "ask"
          "deny"
        ];

        toolPermissionWithSubs = lib.types.either toolPermission (lib.types.attrsOf toolPermission);

        agentType = lib.types.submodule {
          options = {
            description = lib.mkOption {
              description = "A description of what this agent does.";
              type = lib.types.str;
            };
            mode = lib.mkOption {
              description = "The mode of the agent, primary or subagent";
              type = lib.types.str;
              default = "subagent";
            };
            model = lib.mkOption {
              description = "The model to use for this agent.";
              type = lib.types.str;
              default = "opus4.5";
            };
            tools = lib.mkOption {
              description = "Tools with their permission levels. Key is tool name, value is permission.";
              type = lib.types.attrsOf toolPermission;
              default = { };
            };
            extraMeta = lib.mkOption {
              description = "Additional flexible key-value metadata for agent-specific fields.";
              type = lib.types.attrsOf lib.types.str;
              default = { };
            };
            content = lib.mkOption {
              description = "Path to the markdown file containing the agent's prompt.";
              type = lib.types.path;
            };
          };
        };

        itemType = lib.types.submodule {
          options = {
            description = lib.mkOption {
              description = "A description of what this item does.";
              type = lib.types.str;
            };
            extraMeta = lib.mkOption {
              description = "Additional flexible key-value metadata. Each coding agent interprets relevant keys.";
              type = lib.types.attrsOf lib.types.str;
              default = { };
            };
            content = lib.mkOption {
              description = "Path to the markdown file containing the content.";
              type = lib.types.path;
            };
          };
        };

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
            type = lib.types.attrsOf agentType;
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

          tools = lib.mkOption {
            description = ''
              Global tool permissions. Key is tool name, value is either:
              - A simple permission: "allow", "ask", or "deny"
              - An attrset of command patterns to permissions for fine-grained control
              Example: { bash = { "git log*" = "allow"; "rm*" = "deny"; }; read = "allow"; }
            '';
            type = lib.types.attrsOf toolPermissionWithSubs;
            default = { };
          };
        };

        config.hdwlinux.ai.agent.tools = {
          bash = {
            "*" = "ask";
            "bat*" = "allow";
            "cat*" = "allow";
            "cd*" = "allow";
            "echo*" = "allow";
            "find*" = "allow";
            "grep*" = "allow";
            "head*" = "allow";
            "jj*" = "allow";
            "ls*" = "allow";
            "nix*" = "allow";
            "pwd*" = "allow";
            "reboot*" = "deny";
            "rg*" = "allow";
            "rm*" = "ask";
            "shutdown*" = "deny";
            "sudo*" = "deny";
            "tail*" = "allow";
            "xargs*" = "allow";
            "*/skills/*/bin/*" = "allow";
          };
          edit = "allow";
          external_directory = "ask";
          glob = "allow";
          grep = "allow";
          list = "allow";
          question = "allow";
          read = {
            "*" = "allow";
            "*.env" = "deny";
            "*.env.*" = "deny";
          };
          skill = "allow";
          task = "allow";
          todoread = "allow";
          todowrite = "allow";
          webfetch = "allow";
          websearch = "allow";
        };
      };
  };
}
