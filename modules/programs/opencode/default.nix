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
        # Resolve an alias to its ordered "provider/model" fallback chain.
        # First entry is the primary model.
        resolveAliases =
          aliasName:
          let
            alias = config.hdwlinux.ai.clients.models.aliases.${aliasName};
          in
          map (m: "${m.provider}/${m.model}") alias.models;

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

        ruleInstructions = lib.mapAttrsToList (
          name: _rule: "${config.home.homeDirectory}/.config/opencode/prompts/rules/${name}.md"
        ) config.hdwlinux.ai.clients.rules;

        # Provider metadata: OpenCode-specific configuration for each provider
        providerMeta = {
          "llama.cpp" = {
            package = "aisdk:@ai-sdk/openai-compatible";
            settings = lib.optionalAttrs (config.hdwlinux ? services.llama-cpp) {
              baseURL = "http://${config.hdwlinux.services.llama-cpp.host}:${toString config.hdwlinux.services.llama-cpp.port}/v1";
            };
            # llama.cpp models may have additional opencode-specific settings
            transformModel =
              slug: model:
              let
                llmModel = config.hdwlinux.ai.llm.models.${slug} or { };
                oc = llmModel.settings.opencode or { };
              in
              {
                modelID = slug;
                name = model.displayName;
                limit = {
                  context = model.limits.context;
                  output = model.limits.output;
                };
              }
              // lib.optionalAttrs (oc ? tool_call) { capabilities.tools = oc.tool_call; };
          };
        };

        # Build providers config from hdwlinux.ai.clients.models.providers
        # Only include providers that have metadata and at least one model —
        # a provider with metadata but no models (e.g. grove on personal
        # hosts) would render as an empty entry.
        providers =
          lib.mapAttrs
            (
              providerKey: provider:
              let
                # Provider modules can carry their own OpenCode wiring
                # (settings.opencode); the static metadata below covers the
                # providers that don't.
                meta = providerMeta.${providerKey} or (provider.settings.opencode or { });
                transformModel =
                  meta.transformModel or (slug: model: {
                    modelID = slug;
                    name = model.displayName;
                    limit = {
                      context = model.limits.context;
                      output = model.limits.output;
                    };
                  });
              in
              lib.filterAttrs (_: value: value != null) {
                package = meta.package or null;
                name = provider.displayName;
                models = lib.mapAttrs (slug: model: transformModel slug model) provider.models;
              }
              // lib.optionalAttrs (meta ? settings && meta.settings != { }) { inherit (meta) settings; }
              // lib.optionalAttrs (meta ? headers && meta.headers != { }) { inherit (meta) headers; }
              // lib.optionalAttrs (meta ? env && meta.env != [ ]) { inherit (meta) env; }
            )
            (
              lib.filterAttrs (_: p: p.models != { }) (
                lib.filterAttrs (
                  k: p: providerMeta ? ${k} || p.settings ? opencode
                ) config.hdwlinux.ai.clients.models.providers
              )
            );

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
                  oauth = if server.http.oauth == null then { } else mcpOauth server.http.oauth;
                }
            )
            # oh-my-opencode-slim supplies Context7 itself; avoid starting the shared
            # local server a second time for OpenCode. Other clients still receive it.
            # Same for plannotator-inbox: OpenCode takes the @plannotator/opencode
            # plugin (programs.opencode.plannotator), whose replies arrive inside
            # the session — the stdio server is Claude Code's connection.
            (
              lib.removeAttrs config.hdwlinux.ai.clients.mcpServers [
                "context7-mcp"
                "plannotator-inbox"
              ]
            );

      in
      {
        # The launcher scope: every secret the MCP servers and model providers
        # reference, aggregated here so OpenCode's {env:...} substitution can
        # resolve them at exec time.
        secretspec.scopes.ai_clients_opencode.secrets =
          config.hdwlinux.ai.clients.mcpServersSecretNames ++ config.hdwlinux.ai.clients.providerSecretNames;
        xdg.configFile = lib.mkMerge [
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

          package = wrap.package {
            package = pkgs.opencode;
            name = "opencode";
            secrets.scope = "ai_clients_opencode";
          };

          # The MCP servers are rendered below rather than taken from
          # programs.mcp.servers, which cannot carry a secret header.
          enableMcpIntegration = false;

          themes.hdwlinux = opencodeTheme;

          skills = config.hdwlinux.ai.clients.skills;

          settings = {
            providers = providers // {
              agentgateway = {
                package = "@opencode/ai/providers/openai-compatible";
                settings.baseURL = "https://agents.wilsonfamilyhq.com/v1";
              };
            };
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

  # Keycloak-backed OIDC for the agentgateway provider; the plugin is packaged
  # locally and carries the connection options.
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
              baseUrl = "https://agents.wilsonfamilyhq.com/v1";
              callbackPort = 52818;
              clientId = "opencode";
              issuer = "https://auth.wilsonfamilyhq.com/realms/wilsonfamilyhq.com";
              offlineAccess = true;
              providerId = "agentgateway";
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

  # Interactive plan review: exposes submit_plan to OpenCode's built-in plan
  # agent via the default plan-agent workflow. The wrapped OpenCode build takes
  # the plugin's CLI runtime fallback, so the CLI must be on PATH. The plugin
  # also carries the Plannotator Inbox tool — off until config.json says
  # otherwise (the activation below) — the channel agents use to leave
  # questions, summaries and reviews for the person without a session open.
  config.substrate.modules.programs.opencode.plannotator = {
    tags = [
      "profile:ai"
    ];

    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.plannotator ];

        programs.opencode.settings.plugins = [
          "@plannotator/opencode"
        ];

        # The Inbox server: agent tool calls start a stopped one, but on a
        # fresh boot nothing does until then — and the herdr panel reads it
        # from the first press. One idempotent start at login: it attaches
        # to a running server, and daemonizes out of systemd's reach (agent
        # calls bring a dead one back).
        systemd.user.services.plannotator-inbox = {
          Unit.Description = "Plannotator Inbox: messages between coding agents and the person";
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${lib.getExe pkgs.hdwlinux.plannotator} inbox --background";
          };
          Install.WantedBy = [ "default.target" ];
        };

        # The Inbox's own Settings page writes config.json too, so merge in
        # place and touch the file only when the flag is not set yet.
        home.activation.plannotatorInboxTool = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          f="$HOME/.local/share/plannotator/config.json"
          tmp="$(mktemp)"
          if [ -f "$f" ]; then
            ${pkgs.jq}/bin/jq '.inboxTool = ((.inboxTool // {}) + { opencode: true })' "$f" >"$tmp"
          else
            printf '{"inboxTool":{"opencode":true}}\n' >"$tmp"
          fi
          if cmp -s "$tmp" "$f"; then
            rm -f "$tmp"
          else
            run mkdir -p "$(dirname "$f")"
            run mv "$tmp" "$f"
            verboseEcho "plannotator: inbox tool enabled for OpenCode"
          fi
        '';
      };
  };

  config.substrate.modules.programs.opencode.oh-my-opencode-slim = {
    tags = [
      "profile:ai"
    ];

    homeManager =
      {
        config,
        ...
      }:
      let
        # Resolve an alias to its ordered "provider/model" fallback chain consumed by
        # oh-my-opencode-slim. First entry is the primary model.
        resolveAliases =
          aliasName:
          let
            alias = config.hdwlinux.ai.clients.models.aliases.${aliasName};
          in
          map (m: "${m.provider}/${m.model}") alias.models;

        # A single host-aware preset: aliases resolve to opencode-go models on personal
        # hosts and grove models on the work host, so no per-host preset switching is needed
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
