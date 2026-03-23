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

        # Base options shared by all item types (agents, commands, rules)
        itemOptions = {
          description = lib.mkOption {
            description = "A description of what this item does.";
            type = lib.types.str;
          };
          prompt = lib.mkOption {
            description = "Path to the markdown file containing the prompt.";
            type = lib.types.path;
          };
        };

        agentType = lib.types.submodule {
          options = itemOptions // {
            color = lib.mkOption {
              description = "Hex color for the agent (with #, e.g. \"#89b4fa\"). Sourced from the active theme.";
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
              default = "";
            };
            temperature = lib.mkOption {
              description = "Model temperature controlling response creativity/determinism.";
              type = lib.types.float;
            };
            tools = lib.mkOption {
              description = "Tools with their permission levels. Key is tool name, value is permission.";
              type = lib.types.attrsOf toolPermission;
              default = { };
            };
          };
        };

        commandType = lib.types.submodule {
          options = itemOptions // {
            argumentHint = lib.mkOption {
              description = "Hint shown to the user describing expected arguments for this command.";
              type = lib.types.str;
            };
          };
        };

        ruleType = lib.types.submodule {
          options = itemOptions // {
            loadMode = lib.mkOption {
              description = "Controls when the rule is loaded: always (every prompt) or auto (agent-requested when relevant).";
              type = lib.types.enum [
                "always"
                "auto"
              ];
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
            type = lib.types.attrsOf commandType;
            default = { };
          };

          mcpServers = lib.mkOption {
            description = "MCP servers to configure for AI assistants.";
            type = lib.types.attrsOf mcpServerType;
            default = { };
          };

          rules = lib.mkOption {
            description = "Rule definitions for AI assistants.";
            type = lib.types.attrsOf ruleType;
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

        # Map hdwlinux MCP server definitions to programs.mcp.servers so that
        # any program with enableMcpIntegration can pick them up automatically.
        config.programs.mcp = {
          enable = true;
          servers = lib.mapAttrs (
            _: server:
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
              throw "Unknown MCP server type"
          ) config.hdwlinux.ai.agent.mcpServers;
        };

        config.hdwlinux.ai.agent.tools = {
          bash = {
            "*" = "allow";

            "git *" = "deny";
            "reboot *" = "deny";
            "rm -rf *" = "deny";
            "shutdown *" = "deny";
            "su *" = "deny";
            "sudo *" = "deny";
            "ssh *.10gen.cc" = "deny";

            "aws *" = "ask";
            "az *" = "ask";
            "gcloud *" = "ask";
            "jj git push" = "ask";
            "jj git push *" = "ask";
            "kubectl *" = "ask";
            "op *" = "ask";
            "ssh *" = "ask";
            "terraform apply *" = "ask";
          };
          edit = {
            "*" = "allow";

            "**/.env" = "deny";
            "**/.env.*" = "deny";

            "**/secrets/**" = "ask";
          };
          external_directory = {
            "*" = "ask";
            "~/Projects/*" = "allow";
            "/nix/store/*" = "allow";
            "/tmp/*" = "allow";
          };
          glob = "allow";
          grep = "allow";
          list = "allow";
          question = "allow";
          read = {
            "*" = "allow";
            # Environment files
            "./.env" = "deny";
            "./.env.*" = "deny";
            "**/.env" = "deny";
            "**/.env.*" = "deny";
            # Credential and key files
            "**/*.jks" = "deny";
            "**/*.key" = "deny";
            "**/*.keystore" = "deny";
            "**/*.p12" = "deny";
            "**/*.pem" = "deny";
            "**/*.pfx" = "deny";
            # Sensitive config directories
            "~/.aws/*" = "deny";
            "~/.config/gcloud/*" = "deny";
            "~/.git-credentials" = "deny";
            "~/.kanopy/**" = "deny";
            "~/.kube/*" = "deny";
            "~/.ssh/*" = "deny";
            # Infrastructure state
            "**/terraform.tfstate" = "deny";
            "**/terraform.tfstate.backup" = "deny";
            # Secrets directories require confirmation
            "./secrets/**" = "ask";
            "**/secrets/**" = "ask";
          };
          skill = "allow";
          task = "allow";
          todoread = "allow";
          todowrite = "allow";
          webfetch = "allow";
          websearch = "allow";
          write = {
            "*" = "allow";
            # Environment files
            "./.env*" = "deny";
            "**/.env*" = "deny";
            # Credential and key files
            "**/*.key" = "deny";
            "**/*.p12" = "deny";
            "**/*.pem" = "deny";
            # Sensitive config directories
            "~/.kanopy/**" = "deny";
            "~/.ssh/*" = "deny";
            # Infrastructure state
            "**/terraform.tfstate" = "deny";
            "**/terraform.tfstate.backup" = "deny";
            # Secrets directories require confirmation
            "./secrets/**" = "ask";
            "**/secrets/**" = "ask";
          };
        };
      };
  };
}
