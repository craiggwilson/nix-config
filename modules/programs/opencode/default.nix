{
  config.substrate.modules.programs.opencode = {
    tags = [
      "ai:agent"
    ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # Resolve an alias to "provider/model" format for OpenCode
        resolveAlias =
          aliasName:
          let
            alias = config.hdwlinux.ai.agent.models.aliases.${aliasName};
          in
          "${alias.provider}/${alias.model}";

        # Transform MCP servers to OpenCode format
        mcpConfig = lib.mapAttrs (
          name: server:
          if server ? stdio then
            {
              type = "local";
              command = [ server.stdio.command ] ++ server.stdio.args;
              enabled = true;
            }
          else if server ? http then
            {
              type = "remote";
              url = server.http.url;
              headers = server.http.headers;
              enabled = true;
            }
          else
            throw "Unknown MCP server type for ${name}"
        ) config.hdwlinux.ai.agent.mcpServers;

        # Transform tools attrset for OpenCode config (boolean values)
        # "allow" -> true, "ask"/"deny" -> false
        transformTools = tools: lib.mapAttrs (_: perm: perm == "allow") tools;

        # Transform agents to OpenCode JSON config format
        # Uses {file:path} syntax for OpenCode's variable substitution
        agentConfig = lib.mapAttrs (
          _: agent:
          {
            color = agent.color;
            description = agent.description;
            mode = agent.mode;
            model = resolveAlias agent.model;
            prompt = "{file:${builtins.unsafeDiscardStringContext (toString agent.prompt)}}";
            temperature = agent.temperature;
          }
          // lib.optionalAttrs (agent.tools != { }) { tools = transformTools agent.tools; }
        ) config.hdwlinux.ai.agent.agents;

        # Transform commands to OpenCode JSON config format
        # Uses {file:path} syntax for OpenCode's variable substitution
        commandConfig = lib.mapAttrs (_: command: {
          description = command.description;
          template = "{file:${builtins.unsafeDiscardStringContext (toString command.prompt)}}";
        }) config.hdwlinux.ai.agent.commands;

        # Build a derivation containing symlinks to all skills
        # OpenCode expects: skills/<name>/SKILL.md (must be files for discovery)
        skillsDir = pkgs.linkFarm "opencode-skills" (
          lib.mapAttrsToList (name: path: {
            inherit name;
            path = path;
          }) config.hdwlinux.ai.agent.skills
        );

        # Collect all rules as direct file paths for OpenCode's instructions config
        # Uses absolute paths to source files in the nix store
        ruleInstructions = lib.mapAttrsToList (
          _: rule: builtins.unsafeDiscardStringContext (toString rule.prompt)
        ) config.hdwlinux.ai.agent.rules;

        # Provider metadata: OpenCode-specific configuration for each provider
        providerMeta = {
          augment = {
            npm = "file://${config.home.homeDirectory}/Projects/opencode/opencode-augment-provider";
          };

          "llama.cpp" = {
            npm = "@ai-sdk/openai-compatible";
            options = lib.optionalAttrs (config.hdwlinux ? services.llama-cpp) {
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
                name = model.displayName;
                limit = {
                  context = model.limits.context;
                  output = model.limits.output;
                };
              }
              // lib.optionalAttrs (oc ? reasoning) { inherit (oc) reasoning; }
              // lib.optionalAttrs (oc ? tool_call) { inherit (oc) tool_call; };
          };
        };

        # Build providers config from hdwlinux.ai.agent.models.providers
        # Only include providers that have metadata defined
        providers = lib.mapAttrs (
          providerKey: provider:
          let
            meta = providerMeta.${providerKey} or { };
            transformModel =
              meta.transformModel or (slug: model: {
                name = model.displayName;
                limit = {
                  context = model.limits.context;
                  output = model.limits.output;
                };
              });
          in
          {
            npm = meta.npm or null;
            name = provider.displayName;
            models = lib.mapAttrs (slug: model: transformModel slug model) provider.models;
          }
          // lib.optionalAttrs (meta ? options && meta.options != { }) { inherit (meta) options; }
        ) (lib.filterAttrs (k: _: providerMeta ? ${k}) config.hdwlinux.ai.agent.models.providers);

        # mestra plugin source directory — built from the mestra flake
        mestraPluginDir = "${pkgs.mestra.opencode-plugin}/lib/opencode-mestra-plugin";

        # oh-my-openagent plugin directory in the nix store
        ohMyOpenagentDir = "${pkgs.callPackage ./plugins/_oh-my-openagent.nix { }}/lib/oh-my-openagent";

        # oh-my-openagent plugin configuration
        ohMyOpenagentConfig = {
          "$schema" =
            "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json";

          dynamic_context_pruning = {
            enabled = true;
            notification = "minimal";
          };

          hashline_edit = true;

          # MCP servers are managed by Nix; disable plugin-installed ones
          disabled_mcps = [
            "context7"
            "grep_app"
            "websearch"
          ];
          # Override each agent's model to use the augment provider exclusively.
          # oh-my-openagent's built-in fallback chains reference providers
          # (anthropic, openai, google) that are not configured here.
          agents = {
            # Primary orchestrator — balanced model for planning and delegation
            sisyphus = {
              model = resolveAlias "balanced";
            };
            # Deep strategic reasoning — most capable model
            oracle = {
              model = resolveAlias "analyst";
            };
            # Planner — delegates to sisyphus model by default; keep it there
            prometheus = {
              prompt_append = "Leverage deep & quick agents heavily, always in parallel.";
            };
            # Research and doc lookup — balanced is fine
            librarian = {
              model = resolveAlias "balanced";
            };
            # Codebase search and discovery — fast model sufficient
            explore = {
              model = resolveAlias "fast";
            };
            # Autonomous deep worker — coder model
            hephaestus = {
              model = resolveAlias "coder";
            };
            # Multimodal tasks not needed; disable to avoid fallback confusion
            multimodal-looker = {
              disable = true;
            };
          };
          # Category overrides — control what model task() picks when delegating
          categories = {
            quick = {
              model = resolveAlias "fast";
            };
            unspecified-low = {
              model = resolveAlias "balanced";
            };
            unspecified-high = {
              model = resolveAlias "analyst";
            };
            writing = {
              model = resolveAlias "writer";
            };
            # visual-engineering and other GPU-heavy categories fall back to analyst
            visual-engineering = {
              model = resolveAlias "coder";
            };
          };
          # tmux pane spawning for sub-agents
          tmux = {
            enabled = true;
            layout = "main-vertical";
            main_pane_size = 60;
          };
        };

        # OpenCode configuration
        opencodeConfig = {
          "$schema" = "https://opencode.ai/config.json";
          provider = providers;
          mcp = mcpConfig;
          agent = agentConfig;
          command = commandConfig;
          instructions = ruleInstructions;
          permission = config.hdwlinux.ai.agent.tools;
          small_model = resolveAlias "fast";
          plugin = [
            "file://${ohMyOpenagentDir}"
            #"file://${mestraPluginDir}"
          ];
          keybinds = {
            "app_exit" = "ctrl+q";
          };
        };

        # Wrapper that picks a random available port, exports it as OPENCODE_PORT
        # so that oh-my-openagent tmux integration can connect, then launches opencode.
        # Only injects --port if the caller has not already supplied one, so that
        # tools (e.g. the SDK's createOpencodeServer) can pass their own port without
        # ending up with two conflicting --port flags.
        opencodeWrapped = pkgs.writeShellScriptBin "opencode" ''
          case " $* " in
            *" --port"*)
              # Caller supplied --port; extract it for OPENCODE_PORT so the
              # tmux integration can still connect, then pass args through as-is.
              port=$(echo "$*" | grep -oP '(?<=--port[= ])\d+')
              export OPENCODE_PORT="$port"
              exec ${pkgs.opencode}/bin/opencode "$@"
              ;;
            *" attach "*)
              # 'attach' subcommand connects to an existing server via URL — it
              # does not accept --port.  Pass through unchanged; extract the port
              # from the URL so OPENCODE_PORT is still available if needed.
              port=$(echo "$*" | grep -oP '(?<=:)\d+(?=/)')
              [ -n "$port" ] && export OPENCODE_PORT="$port"
              exec ${pkgs.opencode}/bin/opencode "$@"
              ;;
            *)
              # No --port supplied; pick a free port and inject it.
              port=$(${pkgs.python3}/bin/python3 -c "import socket; s=socket.socket(); s.bind((\"\", 0)); print(s.getsockname()[1]); s.close()")
              export OPENCODE_PORT="$port"
              exec ${pkgs.opencode}/bin/opencode --port "$port" "$@"
              ;;
          esac
        '';

      in
      {
        home.packages = [
          opencodeWrapped
          pkgs.opencode-desktop
        ];

        home.file = {
          ".config/opencode/opencode.json".text = builtins.toJSON opencodeConfig;
          ".config/opencode/oh-my-openagent.json".text = builtins.toJSON ohMyOpenagentConfig;
          ".config/opencode/skills".source = skillsDir;
        };
      };
  };
}
