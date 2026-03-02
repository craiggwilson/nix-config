{
  config.substrate.modules.ai.agent.options = {
    tags = [
      "ai:agent"
    ];
    homeManager =
      { config, lib, ... }:
      let
        # Resolve an alias to its full model info including provider.
        # Returns the model with provider info attached.
        resolveAlias =
          aliasName:
          let
            aliases = config.hdwlinux.ai.agent.models.aliases;
            providers = config.hdwlinux.ai.agent.models.providers;
            alias = aliases.${aliasName} or null;
            provider = if alias != null then providers.${alias.provider} or null else null;
            model = if provider != null then provider.models.${alias.model} or null else null;
          in
          if alias == null then
            throw "Alias '${aliasName}' not found"
          else if provider == null then
            throw "Provider '${alias.provider}' not found for alias '${aliasName}'"
          else if model == null then
            throw "Model '${alias.model}' not found in provider '${alias.provider}'"
          else
            model
            // {
              provider = {
                name = provider.name;
                displayName = provider.displayName;
              };
            };

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
          resolveAlias = lib.mkOption {
            description = ''
              Function to resolve an alias to its full model info including provider.
              Returns the model with provider info attached.
              Usage: resolveAlias "coding"
            '';
            type = lib.types.functionTo lib.types.anything;
            readOnly = true;
            default = resolveAlias;
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
            "cp *" = "allow";
            "echo *" = "allow";
            "find *" = "allow";
            "grep *" = "allow";
            "head *" = "allow";
            "jj *" = "allow";
            "jq *" = "allow";
            "ls *" = "allow";
            "mkdir *" = "allow";
            "mv *" = "allow";
            "nix *" = "allow";
            "pwd *" = "allow";
            "rg *" = "allow";
            "rm *" = "allow";
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
