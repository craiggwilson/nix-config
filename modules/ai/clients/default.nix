{
  config.substrate.modules.ai.clients.options = {
    tags = [
      "ai:clients"
    ];
    homeManager =
      {
        config,
        lib,
        ...
      }:
      let
        # Resolve one provider/model entry to its full model info including provider.
        # Returns the model with provider info attached.
        resolveModel =
          entry:
          let
            providers = config.hdwlinux.ai.clients.models.providers;
            provider = providers.${entry.provider} or null;
            model = if provider != null then provider.models.${entry.model} or null else null;
          in
          if provider == null then
            throw "Provider '${entry.provider}' not found for alias entry '${entry.provider}/${entry.model}'"
          else if model == null then
            throw "Model '${entry.model}' not found in provider '${entry.provider}'"
          else
            model
            // {
              provider = {
                inherit (provider) name displayName;
              };
            };

        # Resolve an alias to its full ordered fallback chain of model infos.
        # The first entry is the primary model; subsequent entries are fallbacks.
        resolveAliases =
          aliasName:
          let
            aliases = config.hdwlinux.ai.clients.models.aliases;
            alias = aliases.${aliasName} or null;
          in
          if alias == null then throw "Alias '${aliasName}' not found" else map resolveModel alias.models;

        # Resolve an alias to its primary (first) model info.
        resolveAlias = aliasName: lib.head (resolveAliases aliasName);

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

        taskType = lib.types.submodule {
          options = {
            after = lib.mkOption {
              description = ''
                Names of other tasks this task must wait for: the task's service
                is ordered after theirs (systemd `After=`), so it starts only
                once they finish. Use for tasks that consume another's output.
              '';
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
            agent = lib.mkOption {
              description = "Named agent to run the task. Defaults to the harness's default agent.";
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            autoApprove = lib.mkOption {
              description = "Auto-approve permissions not explicitly denied. Required for unattended runs, since an \"ask\" permission would block forever.";
              type = lib.types.bool;
              default = true;
            };
            continueSession = lib.mkOption {
              description = "Continue the previous session so recurring runs build on prior state.";
              type = lib.types.bool;
              default = false;
            };
            description = lib.mkOption {
              description = "A description of what this task does.";
              type = lib.types.str;
            };
            environment = lib.mkOption {
              description = ''
                Extra environment variables exported before the task runs, as
                shell `export KEY="VALUE"` lines. Values are written verbatim, so
                they may reference secrets injected by `secretsScope` at runtime
                (e.g. `GH_TOKEN = "$GITHUB_API_TOKEN"`).
              '';
              type = lib.types.attrsOf lib.types.str;
              default = { };
            };
            model = lib.mkOption {
              description = "Model alias to use for this task. Defaults to the harness's default model.";
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            packages = lib.mkOption {
              description = "Extra packages placed on the task's PATH (e.g. CLIs the agent shells out to).";
              type = lib.types.listOf lib.types.package;
              default = [ ];
            };
            prompt = lib.mkOption {
              description = "Path to the markdown file containing the task prompt.";
              type = lib.types.path;
            };
            schedule = lib.mkOption {
              description = "systemd OnCalendar specification, e.g. \"daily\" or \"Mon *-*-* 09:00:00\".";
              type = lib.types.str;
            };
            secretsScope = lib.mkOption {
              description = ''
                secretspec scope wrapped around the task. When set, the scope's
                secrets are resolved and injected into the task's environment at
                exec time (via `wrap.package`); the scope must be declared in
                `secretspec.scopes`.
              '';
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            timeout = lib.mkOption {
              description = "Maximum runtime of a single task invocation, as a systemd time span.";
              type = lib.types.str;
              default = "1h";
            };
            workingDirectory = lib.mkOption {
              description = "Directory the task runs in. \"~\" expands to the user's home directory.";
              type = lib.types.str;
              default = "~";
            };
          };
        };

        # A header whose value cannot be a Nix string: baking the value in would
        # put it in the world-readable store.
        #
        # This records *that* a header needs a secret, not how to spell it.
        # Each client renders it its own way -- OpenCode substitutes {env:NAME}
        # from its own environment, for instance -- so no encoding lives here.
        secretHeaderType = lib.types.submodule {
          options = {
            secret = lib.mkOption {
              description = "Name of the `secretspec` entry holding the header value.";
              type = lib.types.str;
            };

            prefix = lib.mkOption {
              description = "Literal text placed before the secret, such as `\"Bearer \"`.";
              type = lib.types.str;
              default = "";
            };
          };
        };

        mcpServerSecretNames =
          server:
          if server ? http then
            lib.foldl' (acc: value: if builtins.isString value then acc else acc ++ [ value.secret ]) [ ] (
              builtins.attrValues server.http.headers
            )
          else
            [ ];

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
                  description = ''
                    HTTP headers to include in requests. A value is either a
                    literal string or `{ secret = "NAME"; prefix = "..."; }`
                    naming a `secretspec` entry, for a header that carries a
                    secret.
                  '';
                  type = lib.types.attrsOf (lib.types.either lib.types.str secretHeaderType);
                  default = { };
                };
              };
            };
          };
        };
      in
      {
        options.hdwlinux.ai.clients = {
          resolveAlias = lib.mkOption {
            description = ''
              Function to resolve an alias to its primary model info including provider.
              Returns the model with provider info attached.
              Usage: resolveAlias "coding"
            '';
            type = lib.types.functionTo lib.types.anything;
            readOnly = true;
            default = resolveAlias;
          };

          resolveAliases = lib.mkOption {
            description = ''
              Function to resolve an alias to its full ordered fallback chain of model infos.
              Each entry has provider info attached. The first entry is the primary model.
              Usage: resolveAliases "coding"
            '';
            type = lib.types.functionTo lib.types.anything;
            readOnly = true;
            default = resolveAliases;
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

          mcpServersSecretNames = lib.mkOption {
            description = ''
              Every `secretspec` entry referenced by any MCP server's headers. A
              client uses this to request the secrets it needs in its own
              environment, however it chooses to consume them.
            '';
            type = lib.types.listOf lib.types.str;
            readOnly = true;
            default = lib.unique (
              lib.concatMap mcpServerSecretNames (lib.attrValues config.hdwlinux.ai.clients.mcpServers)
            );
          };

          mcpServersWithoutSecrets = lib.mkOption {
            description = ''
              The MCP servers whose headers carry no secret. A client with no way
              to supply one takes this subset, so a server it cannot authenticate
              to is left out instead of breaking evaluation.
            '';
            type = lib.types.attrsOf mcpServerType;
            readOnly = true;
            default = lib.filterAttrs (
              _: server: mcpServerSecretNames server == [ ]
            ) config.hdwlinux.ai.clients.mcpServers;
          };

          providerSecretNames = lib.mkOption {
            description = ''
              Names of the `secretspec` entries providers declared with
              `models.providers.<name>.secret`. A client uses this to request
              the secrets it needs in its own environment.
            '';
            type = lib.types.listOf lib.types.str;
            readOnly = true;
            default = lib.unique (
              lib.filter (s: s != null) (
                map (p: p.secret) (lib.attrValues config.hdwlinux.ai.clients.models.providers)
              )
            );
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

          tasks = lib.mkOption {
            description = ''
              Scheduled agent tasks. Definitions are harness-agnostic; the enabled
              harness module (e.g. opencode) renders each task into a systemd user
              service and timer.
            '';
            type = lib.types.attrsOf taskType;
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

        # Map hdwlinux MCP server definitions to programs.mcp.servers so that any
        # program with enableMcpIntegration can pick them up automatically.
        #
        # programs.mcp.servers carries literal strings only, so a server needing a
        # secret is left out. Clients that can supply one -- OpenCode and Claude
        # Code, for two -- read hdwlinux.ai.clients.mcpServers directly.
        # MCP servers carry their own secret references (secretHeaderType);
        # the harness modules aggregate them (plus provider keys) into the
        # scope their launcher wrapper resolves.
        config.programs.mcp = {
          enable = true;
          servers = lib.mapAttrs (
            _: server:
            if server ? stdio then
              {
                command = server.stdio.command;
                args = server.stdio.args;
              }
            else
              {
                url = server.http.url;
                headers = server.http.headers;
              }
          ) config.hdwlinux.ai.clients.mcpServersWithoutSecrets;
        };

        config.hdwlinux.ai.clients.tools = {
          bash = {
            "*" = "allow";

            "git *" = "deny";
            "reboot *" = "deny";
            "rm -rf *" = "deny";
            "secretspec *" = "deny";
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
            "~/.cargo/*" = "allow";
            "~/.config/opencode/*" = "allow";
            "~/.local/share/opencode/worktree/*" = "allow";
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
