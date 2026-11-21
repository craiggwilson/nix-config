{
  config.substrate.modules.programs.opencode = {
    tags = [
      "profile:ai"
    ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        wrap,
        ...
      }:
      let
        agentgatewayGroups = import ./_agentgateway-groups.nix;
        # Resolve an alias to its ordered "provider/model" fallback chain.
        # First entry is the primary model.
        resolveAliases =
          aliasName:
          let
            alias = config.hdwlinux.ai.clients.models.aliases.${aliasName};
          in
          map (agentgatewayGroups.resolve lib) alias.models;

        # Primary "provider/model" for single-model consumers (agent definitions, title)
        resolveAlias = aliasName: lib.head (resolveAliases aliasName);

        # Transform agent-level tool permissions into OpenCode v2 permissions.
        transformTools =
          tools:
          lib.mapAttrsToList (name: effect: {
            action = renameAction name;
            resource = "*";
            inherit effect;
          }) tools;

        # v2 renames: bash -> shell, task -> subagent; write merges into edit.
        renameAction =
          name:
          {
            bash = "shell";
            task = "subagent";
            write = "edit";
          }
          .${name} or name;

        # Convert the v1-style grouped permission map (tool -> "allow"/"ask"/"deny"
        # or pattern -> permission) into opencode v2's ordered permissions array of
        # { action, resource, effect }. Wildcards come first because OpenCode uses
        # the last matching rule.
        permissionArray =
          tools:
          let
            entries = lib.flatten (
              lib.mapAttrsToList (
                action: value:
                let
                  action' = renameAction action;
                in
                if builtins.isString value then
                  [
                    {
                      action = action';
                      resource = "*";
                      effect = value;
                    }
                  ]
                else
                  lib.mapAttrsToList (resource: effect: {
                    action = action';
                    inherit resource effect;
                  }) value
              ) tools
            );
            split = lib.partition (e: e.resource == "*") entries;
          in
          lib.unique (split.right ++ split.wrong);

        agentConfig = lib.mapAttrs (
          name: agent:
          {
            inherit (agent) color description mode;
            model = resolveAlias agent.model;
            system = "{file:${config.home.homeDirectory}/.config/opencode/prompts/agents/${name}.md}";
            request.body.temperature = agent.temperature;
          }
          // lib.optionalAttrs (agent.tools != { }) { permissions = transformTools agent.tools; }
        ) config.hdwlinux.ai.clients.agents;

        commandConfig = lib.mapAttrs (name: command: {
          inherit (command) description;
          template = "{file:${config.home.homeDirectory}/.config/opencode/prompts/commands/${name}.md}";
        }) config.hdwlinux.ai.clients.commands;

        modelProviders = config.hdwlinux.ai.clients.models.providers;

        # OpenCode's spelling of each API format; a provider can pin its own package.
        formatPackages = {
          anthropic = "@opencode/ai/providers/anthropic-compatible";
          completions = "@opencode/ai/providers/openai-compatible";
          gemini = "@opencode/ai/providers/google";
          responses = "@opencode/ai/providers/openai-compatible/responses";
        };

        # The discovery plugin derives agentgateway's groups from this provider;
        # clients already ship the built-in ones.
        providers = lib.mapAttrs (
          _: provider:
          {
            name = provider.displayName;
            package =
              provider.settings.opencode.package or formatPackages.${
                if lib.elem "completions" provider.formats then "completions" else lib.head provider.formats
              };
            settings.baseURL = provider.baseURL;
          }
          // lib.optionalAttrs (provider.auth != null) {
            env = [ provider.auth.secret ];
            headers.${provider.auth.header} = "${provider.auth.prefix}{env:${provider.auth.secret}}";
          }
        ) (lib.filterAttrs (_: p: p.baseURL != null && !p.builtin) modelProviders);
        ruleInstructions = lib.mapAttrsToList (
          name: _rule: "${config.home.homeDirectory}/.config/opencode/prompts/rules/${name}.md"
        ) config.hdwlinux.ai.clients.rules;

        # Opencode theme derived from the active hdwlinux theme colors
        opencodeTheme = import ./_theme.nix config.hdwlinux.theme.colors;

        # OpenCode reads {env:NAME} from its own environment, so a secret header
        # is spelled that way here and the launcher below supplies the value.
        # The registry records only that a secret is needed; this is where that
        # becomes OpenCode's syntax.
        mcpHeaders =
          headers:
          lib.mapAttrs (
            _: value: if builtins.isString value then value else "${value.prefix}{env:${value.secret}}"
          ) headers;

        mcpOauth =
          oauth:
          let
            client = oauth.clients.opencode or { };
          in
          {
            client_id = client.clientId;
            callback_port = client.callbackPort;
            redirect_uri = client.redirectUri;
          }
          // lib.optionalAttrs (oauth.discoveryUrl != null) {
            auth_server_metadata_url = oauth.discoveryUrl;
          }
          // lib.optionalAttrs (oauth.scopes != [ ]) {
            scope = lib.concatStringsSep " " oauth.scopes;
          };

        mcpSecretLoads = lib.concatMapStringsSep "\n" (
          name:
          let
            secretFile = config.secretspec.entries.${name}.file.path;
          in
          ''
            secretName=${lib.escapeShellArg name}
            secretFile=${lib.escapeShellArg secretFile}
            if [[ ! -s "$secretFile" ]]; then
              printf '%s\n' "opencode: MCP secret file for $secretName is missing or empty; restart secretspec-materialize.service" >&2
              exit 1
            fi
            printf -v "$secretName" '%s' "$(<"$secretFile")"
            export "$secretName"
          ''
        ) mcpSecretNames;

        mcpServers =
          lib.mapAttrs
            (
              _: server:
              if server ? stdio then
                {
                  type = "local";
                  command = [ server.stdio.command ] ++ server.stdio.args;
                }
              else
                lib.filterAttrs (_: value: value != { }) {
                  type = "remote";
                  url = server.http.url;
                  headers = mcpHeaders server.http.headers;
                  oauth =
                    if server.http.oauth == null then
                      { }
                    else if builtins.isBool server.http.oauth then
                      server.http.oauth
                    else
                      mcpOauth server.http.oauth;
                }
            )
            # OpenCode uses the shared remote Context7 server; other MCP clients
            # retain the local stdio server.
            (lib.removeAttrs config.hdwlinux.ai.clients.mcpServers [ "context7-mcp" ]);
        mcpSecretNames = config.hdwlinux.ai.clients.mcpServersSecretNames;
        opencodePackage =
          if mcpSecretNames == [ ] then
            pkgs.opencode
          else
            wrap.package {
              package = pkgs.opencode;
              name = "opencode";
              # Load materialized MCP secrets from disk so OpenCode does not
              # resolve 1Password-backed values on every launch.
              preHook = mcpSecretLoads;
            };

      in
      {
        # MCP header secrets are materialized once per login and loaded by the
        # OpenCode launcher, rather than resolved by secretspec at each launch.
        secretspec.entries = lib.genAttrs mcpSecretNames (_: {
          file = { };
        });
        # Keep terminal-only preferences in OpenCode's separate CLI config.
        xdg.configFile = lib.mkMerge [
          {
            "opencode/cli.json" = {
              force = true;
              text = builtins.toJSON {
                "$schema" = "https://opencode.ai/v2/cli.json";
                animations = true;
                diffs.wrap = "word";
                session = {
                  sidebar = "auto";
                  scrollbar = false;
                  thinking = "hide";
                };
                # No session tabs: herdr's multiplexer owns the panes.
                tabs.mode = "off";
                terminal.copy = "manual";
                theme.name = "opencode";
              };
            };
          }
          (lib.mapAttrs' (
            name: command: lib.nameValuePair "opencode/prompts/commands/${name}.md" { source = command.prompt; }
          ) config.hdwlinux.ai.clients.commands)
          (lib.mapAttrs' (
            name: rule: lib.nameValuePair "opencode/prompts/rules/${name}.md" { source = rule.prompt; }
          ) config.hdwlinux.ai.clients.rules)
          (lib.mapAttrs' (
            name: agent: lib.nameValuePair "opencode/prompts/agents/${name}.md" { source = agent.prompt; }
          ) config.hdwlinux.ai.clients.agents)
        ];

        programs.opencode = {
          enable = true;

          package = opencodePackage;

          # The MCP servers are rendered below rather than taken from
          # programs.mcp.servers, which cannot carry a secret header.
          enableMcpIntegration = false;

          themes.hdwlinux = opencodeTheme;

          skills = config.hdwlinux.ai.clients.skills;

          settings = {
            inherit providers;
            # v2 dropped small_model; the built-in title agent carries the fast model now.
            agents = agentConfig // {
              title.model = resolveAlias "fast";
            };
            commands = commandConfig;
            instructions = ruleInstructions;
            permissions = permissionArray config.hdwlinux.ai.clients.tools;
          }
          // lib.optionalAttrs (mcpServers != { }) {
            mcp.servers = mcpServers;
          };
        };
      };
  };

  # Register Keycloak as a reusable OAuth integration for OpenCode providers.
  config.substrate.modules.programs.opencode.keycloak-auth = {
    tags = [
      "profile:ai"
    ];

    homeManager =
      { pkgs, ... }:
      {
        programs.opencode.settings.plugins = [
          {
            package = "${pkgs.hdwlinux.opencode-keycloak-auth}/lib/node_modules/opencode-keycloak-auth";
            options = {
              callbackPort = 52818;
              clientId = "opencode";
              issuer = "https://auth.wilsonfamilyhq.com/realms/wilsonfamilyhq.com";
              offlineAccess = true;
              providerId = "wilsonfamilyhq";
              redirectPath = "/callback";
              scopes = "openid profile email offline_access";
            };
          }
        ];
      };
  };

  config.substrate.modules.programs.opencode.ponytail = {
    tags = [
      "profile:ai"
    ];

    homeManager = {
      programs.opencode.settings.plugins = [
        "@dietrichgebert/ponytail"
      ];
    };
  };

  config.substrate.modules.programs.opencode.oh-my-opencode-slim = {
    tags = [
      "profile:ai"
    ];

    homeManager =
      {
        config,
        lib,
        ...
      }:
      let
        agentgatewayGroups = import ./_agentgateway-groups.nix;
        # Resolve an alias to its ordered "provider/model" fallback chain consumed by
        # oh-my-opencode-slim. First entry is the primary model.
        resolveAliases =
          aliasName:
          let
            alias = config.hdwlinux.ai.clients.models.aliases.${aliasName};
          in
          map (agentgatewayGroups.resolve lib) alias.models;

        # A single host-aware preset: aliases resolve to opencode-go models on personal
        # hosts and AI Gateway models on the work host, so no per-host preset switching is needed
        hdwlinux = {
          orchestrator = {
            model = resolveAliases "orchestration";
          };
          oracle = {
            model = resolveAliases "analysis";
          };
          librarian = {
            model = resolveAliases "research";
            mcps = [
              "context7"
              "gh_grep"
            ];
          };
          explorer = {
            model = resolveAliases "fast";
          };
          designer = {
            model = resolveAliases "balanced";
          };
          fixer = {
            model = resolveAliases "coding";
          };
          observer = {
            model = resolveAliases "writing";
          };
        };
      in
      {
        programs.opencode.settings.plugins = [
          # Unpinned (latest): the @beta dist-tag is stranded at 3.0.0-beta.13,
          # which predates OpenCode v2 multiplexer pane support (3.0.x stable).
          "oh-my-opencode-slim"
        ];

        xdg.configFile."opencode/oh-my-opencode-slim.json" = {
          text = builtins.toJSON {
            multiplexer = {
              type = "auto";
              layout = "main-vertical";
              main_pane_size = 60;
            };
            preset = "hdwlinux";
            disabled_agents = [ ];
            presets = {
              inherit hdwlinux;
            };
          };
        };
      };
  };
}
