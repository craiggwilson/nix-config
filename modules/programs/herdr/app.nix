{
  config.substrate.modules.programs.herdr.app = {
    tags = [
      "profile:ai"
      "profile:programming"
    ];

    homeManager =
      {
        lib,
        pkgs,
        ...
      }:
      let
        herdrApp = pkgs.hdwlinux.herdr-app;

        jsonFormat = pkgs.formats.json { };

        # keys.json's send: values are terminal control characters, spelled
        # here as JSON escapes for fromJSON; toJSON escapes them right back
        # in the generated file.
        sendKey = json: "send:${builtins.fromJSON json}";

        # Desktop keybinds matched to the herdr TUI keymap
        # (modules/programs/herdr/default.nix) on top of herdr-app's shipped
        # defaults. Custom chords are alt/alt+shift only — no leaders, no
        # ctrl additions — and a shipped default our alt chord duplicates is
        # dropped (the palette's alt+p moves to plannotator; the palette
        # stays on the app's ctrl+shift+p). The TUI's prefix (alt+a)
        # bindings have no app equivalent — keys.json binds single chords
        # only — so those actions keep the app's shipped shortcuts. TUI
        # tabs map to app tabs, TUI workspaces to app spaces.
        keys = {
          global = {
            # Pane navigation: TUI focus_pane_* (arrows + hjkl). alt+down/up
            # replace the app default's agent.next/agent.prev.
            "alt-down" = "pane.go:down";
            "alt-h" = "pane.go:left";
            "alt-j" = "pane.go:down";
            "alt-k" = "pane.go:up";
            "alt-left" = "pane.go:left";
            "alt-l" = "pane.go:right";
            "alt-right" = "pane.go:right";
            "alt-up" = "pane.go:up";

            # Pane movement: TUI swap_pane_* (shift + arrows/hjkl).
            "alt-shift-down" = "pane.swap:down";
            "alt-shift-h" = "pane.swap:left";
            "alt-shift-j" = "pane.swap:down";
            "alt-shift-k" = "pane.swap:up";
            "alt-shift-left" = "pane.swap:left";
            "alt-shift-l" = "pane.swap:right";
            "alt-shift-right" = "pane.swap:right";
            "alt-shift-up" = "pane.swap:up";

            # Pane management: TUI zoom, close_pane, split_horizontal
            # (stacked) and split_vertical (side by side).
            "alt-w" = "pane.close";
            "alt-z" = "pane.zoom";
            "alt--" = "pane.split:down";
            "alt-\\" = "pane.split:right";

            # Tabs: TUI new/close/rename/switch/next/previous_tab. alt+1..9
            # replace the app default's space.select — the TUI switches tabs
            # with them and has no numbered space switching.
            "alt-1" = "tab.select:1";
            "alt-2" = "tab.select:2";
            "alt-3" = "tab.select:3";
            "alt-4" = "tab.select:4";
            "alt-5" = "tab.select:5";
            "alt-6" = "tab.select:6";
            "alt-7" = "tab.select:7";
            "alt-8" = "tab.select:8";
            "alt-9" = "tab.select:9";
            "alt-t" = "tab.new";
            "alt-x" = "tab.close";
            "alt-shift-t" = "tab.rename";
            "alt-]" = "tab.next";
            "alt-[" = "tab.prev";

            # Spaces: TUI next/previous_workspace.
            "alt-tab" = "space.next";
            "alt-shift-tab" = "space.prev";

            # Agents: TUI next/previous_agent.
            "alt-shift-." = "agent.next";
            "alt-shift-," = "agent.prev";

            # Mods. plannotator takes the prime chord (its palette
            # replacement stays on the app's ctrl+shift+p).
            "alt-p" = "tab-host.toggle:plannotator";
            "alt-o" = "mod.open:obsidian";
            "alt-m" = "herdwatch.toggle";

            # herdr-app shipped defaults kept (no alt counterpart). New app
            # defaults added by upgrades must be merged in here by hand: an
            # edited keys.json is never rewritten by the app.
            "ctrl-+" = "app.zoom_in";
            "ctrl--" = "app.zoom_out";
            "ctrl-0" = "app.zoom_reset";
            "ctrl-=" = "app.zoom_in";
            "ctrl-?" = "app.help";
            "ctrl-shift-/" = "app.help";
            "ctrl-shift-?" = "app.help";
            "ctrl-shift-b" = "layout.toggle:sidebar";
            "ctrl-shift-n" = "space.new";
            "ctrl-shift-k" = "mod.open:picker";
            "ctrl-shift-p" = "app.palette";
            "ctrl-," = "app.settings";
            "ctrl-shift-l" = "layout.switch";
            "shift-f2" = "space.rename";
          };

          # Terminal focus: herdr-app shipped defaults, kept as is.
          terminal = {
            "ctrl-backspace" = sendKey "\"\\u0017\"";
            "ctrl-left" = sendKey "\"\\u001bb\"";
            "ctrl-right" = sendKey "\"\\u001bf\"";
            "ctrl-shift-c" = "terminal.copy";
            "ctrl-shift-v" = "terminal.paste";
            "ctrl-shift-f" = "terminal.search";
            "ctrl-v" = "terminal.paste_image";
            "ctrl-insert" = "terminal.copy";
            "shift-insert" = "terminal.paste";
          };

          # While the obsidian mod has the keyboard.
          "mod:obsidian" = {
            "alt-enter" = "obsidian.send";
            "alt-j" = "obsidian.next";
            "alt-k" = "obsidian.prev";
            "alt-s" = "obsidian.save";
          };
        };

        keysFile = jsonFormat.generate "herdr-app-keys.json" keys;

        # Obsidian mod config, pinned to the kb vault (the mod's auto-detection
        # needs Obsidian running). Installed once: edits after that stick.
        obsidianConfig = (pkgs.formats.json { }).generate "herdr-app-obsidian.json" {
          vault = "~/Projects/github.com/craiggwilson/kb";
        };

        # Third-party mods, fetched and pinned. To update one, bump both rev
        # and hash: the rev from the repo, the hash from
        # `nix hash path` on the extracted
        # https://github.com/<owner>/<repo>/archive/<rev>.tar.gz tree.
        #
        # What they run, from each repo's own disclosure and a code review:
        # - herdr-app-jj (sebcbi1): jj and git in the space's folder, on
        #   this machine and on connected ones. No network.
        # - herdr-mod-plannotator (gadenbuie): the plannotator CLI, and curl
        #   to the local Inbox on 127.0.0.1 only. Reads Plannotator's store.
        # - herdr-mod-tab-host (gadenbuie): sh -c running the show commands
        #   that installed mods declare in their mod.json.
        # - herdr-ttt (cha2maru): sh/hc to find ttt; if missing it can offer
        #   ttt's install.sh piped to sh, only after a confirm click.
        # - herdwatch (bryan-duarte): ssh to the hosts in
        #   ~/.config/herdwatch/hosts.conf for read-only probes, and the
        #   confirmed actions offered in its console (kill a process tree,
        #   remove a worktree, docker prune) over the same ssh.
        # - herdr-obsidian (cunderw): rg/hc/tail/xdg-open/an editor over the
        #   vault, and ~/.claude transcripts to save an agent's reply.
        jjSrc = pkgs.fetchFromGitHub {
          owner = "sebcbi1";
          repo = "herdr-app-jj";
          rev = "1ffdc17f5f36b50f3ee502fadf5abf3f4742c1fd";
          hash = "sha256-WH5221VZXo6W1kLg390HQha26Y+Mzx9CQWK2QIxcG/c=";
        };
        plannotatorSrc = pkgs.fetchFromGitHub {
          owner = "gadenbuie";
          repo = "herdr-mod-plannotator";
          rev = "d0a156b355f9bba1eb9d20f5abca783fa08d9bd6";
          hash = "sha256-llRI/DWzcp0MSaoT7q5ja0KhYCFc/2pK54UqycsTWLw=";
        };
        tabHostSrc = pkgs.fetchFromGitHub {
          owner = "gadenbuie";
          repo = "herdr-mod-tab-host";
          rev = "e272a8238afe0d7c38e9091b95b3968f408fe57f";
          hash = "sha256-wu0PJBBSPVOuw8b/wRiohc41AMOefqx556Wwa6x+SV0=";
        };
        tttSrc = pkgs.fetchFromGitHub {
          owner = "cha2maru";
          repo = "herdr-ttt";
          rev = "146ecb24ae5b86cba24cb2616e3336d176b9926c";
          hash = "sha256-mAuDH0WTocHDcNt4yTilEHBwYxIjDJmTK7aL+M9iK6o=";
        };
        herdwatchSrc = pkgs.fetchFromGitHub {
          owner = "bryan-duarte";
          repo = "herdwatch";
          rev = "24cf0a34916410087372d0c847123a859a047795";
          hash = "sha256-FdR83Xy1FNSdGg9vVPsZShZGFeo2drpfHAnJ1/1Sp3M=";
        };
        obsidianSrc = pkgs.fetchFromGitHub {
          owner = "cunderw";
          repo = "herdr-obsidian";
          rev = "72e4018e83049b1ae38ac66472e21d69ba8fa7db";
          hash = "sha256-xme4o3BdyD3n4U/eqDQEMGdCDBgbkhW+i6lkEmp5GeI=";
        };

        # jj-workspace: workspaces land in ~/Projects/workspaces/<repo>/<name>
        # (upstream puts them in ~/.herdr/worktrees/<repo>/<name> and offers
        # no config knob for it, hence the one-line substitution).
        jjWorkspaceMod = pkgs.runCommand "herdr-jj-workspace" { } ''
          cp -r ${jjSrc}/mods/jj-workspace $out
          chmod -R +w $out
          substituteInPlace $out/main.js \
            --replace-fail '`''${home}/.herdr/worktrees`' '`''${home}/Projects/workspaces`'
        '';

        # ttt-tabs ships the tab bar's Files/Changes buttons; which appear
        # comes from the app's shared "workspace.panels" state (set once by
        # the welcome screen). Ours is the layout's panel stack — Changes
        # only — so activation rewrites that state to match (below); no
        # patch to the mod.

        # spaces-jj: the shipped spaces sidebar from the app's own source
        # (so it tracks the installed version) plus our jj patch —
        # herdr-app-jj's spaces-icons.patch hand-finished for this app
        # version; its hunk 1 adds the readTextFile import, its hunk 2
        # (roots()) has no counterpart here, its hunk 3 is the check()
        # jj-first insert. See that repo's RECIPE.md. The build fails loudly
        # when the app's spaces mod changes and the patch needs
        # regenerating.
        spacesJjMod =
          pkgs.runCommand "herdr-spaces-jj"
            {
              nativeBuildInputs = [ pkgs.patch ];
            }
            ''
              cp -r ${herdrApp.src}/defaults/mods/spaces $out
              chmod -R +w $out
              (cd $out && patch -p1 < ${./app/spaces-jj.patch})
            '';

        # agents-machines: the shipped agents list with a "Grouped by
        # machine" view, defaulted on (a hand choice in the sort menu still
        # wins — the default only applies while agents.sort is unset). Also
        # from the app's own source; the app restores the shipped "agents"
        # mod whole on every start, so the patched copy lives under a new
        # name and the layout points at it.
        agentsMachinesMod =
          pkgs.runCommand "herdr-agents-machines"
            {
              nativeBuildInputs = [ pkgs.patch ];
              inherit (herdrApp) version;
            }
            ''
              cp -r ${herdrApp.src}/defaults/mods/agents $out
              chmod -R +w $out
              (cd $out && patch -p1 < ${./app/agents-machines.patch})
              printf '{ "place": "none", "title": "Agents", "cloned_from": { "name": "agents", "version": "%s" } }\n' "$version" > $out/mod.json
            '';

        # Every mod to install: name -> source folder. Fetched from the
        # pinned repos above (one with a local substitution for its workspace
        # root), two
        # derived from the app's own shipped mods.
        mods = {
          agents-machines = agentsMachinesMod;
          herdwatch = "${herdwatchSrc}/mods/herdwatch";
          jj-changes = "${jjSrc}/mods/jj-changes";
          jj-menu = "${jjSrc}/mods/jj-menu";
          jj-status = "${jjSrc}/mods/jj-status";
          jj-workspace = jjWorkspaceMod;
          obsidian = "${obsidianSrc}/mods/obsidian";
          plannotator = "${plannotatorSrc}/mods/plannotator";
          spaces-jj = spacesJjMod;
          tab-host = "${tabHostSrc}/mods/tab-host";
          ttt-tabs = "${tttSrc}/mods/ttt-tabs";
        };

        # herdr-app owns its config folder: it rewrites files on upgrade and
        # through its ctrl-alt-shift-escape escape hatch, and it does not
        # hot-reload symlinked mod folders. Config therefore lands as
        # activation copies of store content rather than xdg symlinks.
        installHerdrAppConfig = ''
          app_home="''${XDG_CONFIG_HOME:-$HOME/.config}/herdr-app"
          mkdir -p "$app_home/layouts" "$app_home/mods"

          # Mods first: the app's key parser drops <mod>.<command> bindings
          # whose mod folder is missing at keys.json load time. chmod before
          # rm: an earlier activation's cp -a preserved the store's read-only
          # directory modes, which made rm fail and abort this whole script;
          # chmod after cp so the app can write its type stubs and the next
          # rm works.
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: src: ''
              chmod -R u+w "$app_home/mods/${name}" 2>/dev/null || true
              rm -rf "$app_home/mods/${name}"
              run cp -a ${src} "$app_home/mods/${name}"
              chmod -R u+w "$app_home/mods/${name}"
              verboseEcho "herdr-app: installed mod '${name}'"
            '') mods
          )}

          # Our layout ("hdwlinux"): a clone of the shipped main layout —
          # jj mods, agents grouped by machine, the ttt-tabs + tab-host tab
          # bar, Changes as the only side panel — ours to keep editing;
          # activation overwrites the installed copy. The earlier
          # main-jj.json install of ours is retired.
          rm -f "$app_home/layouts/main-jj.json"
          run install -Dm644 ${./app/layouts/hdwlinux.json} "$app_home/layouts/hdwlinux.json"
          verboseEcho "herdr-app: installed layout hdwlinux"

          run install -Dm644 ${keysFile} "$app_home/keys.json"
          verboseEcho "herdr-app: installed keys.json"

          if [ ! -e "$app_home/obsidian.json" ]; then
            run install -Dm644 ${obsidianConfig} "$app_home/obsidian.json"
            verboseEcho "herdr-app: installed obsidian.json"
          fi

          # hdwlinux is the default layout: activation moves to it from any
          # shipped layout (main, terminals, win98 — the app restores those
          # on every start and offers no way to hide them from the switcher)
          # or from a fresh home with nothing chosen yet. Anything else in
          # layouts/ is a personal layout — a deliberate choice — and is
          # left alone.
          shown="$(${pkgs.jq}/bin/jq -r '.layout // empty' "$app_home/shared.json" 2>/dev/null || true)"
          case "$shown" in
            "" | main | terminals | win98 | main-jj)
              if ! run ${herdrApp}/bin/herdr-app do layout.switch '{"name":"hdwlinux"}'; then
                errorEcho "herdr-app: could not switch layouts (is the app running?); run: herdr-app do layout.switch '{\"name\":\"hdwlinux\"}'"
              fi
              ;;
          esac

          # Panel buttons are welcome-time state in shared.json; ours is the
          # layout's panel stack: Changes only. Rewritten last so a running
          # app's layout save cannot immediately clobber it — but a running
          # app may still overwrite shared state until it restarts, so
          # restart herdr-app after activating. Activation re-asserts.
          shared_src="$app_home/shared.json"
          [ -f "$shared_src" ] || printf '{}' > "$shared_src"
          shared_next="$app_home/shared.json.next"
          if ${pkgs.jq}/bin/jq '.["workspace.panels"] = ["changes"]' "$shared_src" > "$shared_next"; then
            run mv "$shared_next" "$shared_src"
            verboseEcho "herdr-app: set workspace.panels to changes"
          else
            rm -f "$shared_next"
            errorEcho "herdr-app: could not set workspace.panels in shared.json"
          fi
        '';
      in
      {
        home.packages = [ herdrApp ];

        home.activation.herdrAppConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] installHerdrAppConfig;
      };
  };
}
