{
  config.substrate.modules.ai.agent.options = {
    tags = [
      "ai:agent"
    ];
    homeManager =
      { config, lib, ... }:
      let
        # Resolve canonical model name to provider-specific identifier
        # Follows fallback chain if model not available for the provider
        resolveModel =
          provider: canonicalName:
          let
            resolve =
              modelName: visited:
              let
                model = config.hdwlinux.ai.agent.models.${modelName} or (throw "Unknown model: ${modelName}");

                # Check for cycles
                hasCycle = builtins.elem modelName visited;
                visited' = visited ++ [ modelName ];
                cycleError = throw "Cycle detected in model fallback chain: ${builtins.concatStringsSep " -> " visited'}";

                # Try to get provider-specific name
                providerModel = model.providers.${provider} or null;
              in
              if hasCycle then
                cycleError
              else if providerModel != null then
                providerModel
              else if model.fallback != null then
                resolve model.fallback visited'
              else
                throw "Model ${canonicalName} (resolved to ${modelName}) is not available for ${provider}";
          in
          resolve canonicalName [ ];

        toolPermission = lib.types.enum [
          "allow"
          "ask"
          "deny"
        ];

        toolPermissionWithSubs = lib.types.either toolPermission (lib.types.attrsOf toolPermission);

        # Nested extraMeta type: keyed by program name (e.g., augment, opencode), then key-value pairs
        extraMetaType = lib.types.attrsOf (lib.types.attrsOf lib.types.str);

        # Base options shared by items (commands, rules) and agents
        itemOptions = {
          description = lib.mkOption {
            description = "A description of what this item does.";
            type = lib.types.str;
          };
          extraMeta = lib.mkOption {
            description = "Program-specific metadata. Top-level key is program name (e.g., augment, opencode).";
            type = extraMetaType;
            default = { };
          };
          prompt = lib.mkOption {
            description = "Path to the markdown file containing the prompt.";
            type = lib.types.path;
          };
        };

        itemType = lib.types.submodule { options = itemOptions; };

        agentType = lib.types.submodule {
          options = itemOptions // {
            mode = lib.mkOption {
              description = "The mode of the agent, primary or subagent";
              type = lib.types.str;
              default = "subagent";
            };
            model = lib.mkOption {
              description = "The model to use for this agent.";
              type = lib.types.str;
              default = "";
            };
            tools = lib.mkOption {
              description = "Tools with their permission levels. Key is tool name, value is permission.";
              type = lib.types.attrsOf toolPermission;
              default = { };
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
          resolveModel = lib.mkOption {
            description = "Function to resolve a canonical model name to a provider-specific identifier. Takes provider name and canonical model name.";
            type = lib.types.functionTo (lib.types.functionTo lib.types.str);
            readOnly = true;
            default = resolveModel;
          };

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
              Example: { bash = { "git log *" = "allow"; "rm *" = "deny"; }; read = "allow"; }
            '';
            type = lib.types.attrsOf toolPermissionWithSubs;
            default = { };
          };
        };

        config.hdwlinux.ai.agent.tools = {
          bash = {
            "*" = "ask";
            "bat *" = "allow";
            "cat *" = "allow";
            "cd *" = "allow";
            "echo *" = "allow";
            "find *" = "allow";
            "grep *" = "allow";
            "head *" = "allow";
            "jj *" = "allow";
            "jq *" = "allow";
            "ls *" = "allow";
            "nix *" = "allow";
            "pwd *" = "allow";
            "rg *" = "allow";
            "sleep *" = "allow";
            "sort *" = "allow";
            "tail *" = "allow";
            "timeout *" = "allow";
            "xargs *" = "allow";
            "wc *" = "allow";
            "*/skills/*/bin/*" = "allow";

            "git *" = "deny";
            "reboot *" = "deny";
            "shutdown *" = "deny";
            "sudo *" = "deny";
          };
          edit = "allow";
          external_directory = {
            "*" = "ask";
            "~/Projects/*" = "allow";
            "/tmp/*" = "allow";
          };
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
