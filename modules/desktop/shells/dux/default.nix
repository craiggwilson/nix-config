{
  config.substrate.modules.desktop.shells.dux = {
    tags = [ "desktop:shells:dux" ];

    nixos = {
      hdwlinux.desktop.shells.dux.prettyName = "Dux";
    };

    homeManager =
      {
        config,
        inputs,
        lib,
        pkgs,
        wrap,
        hasTag,
        ...
      }:
      let
        colors = config.hdwlinux.theme.colors.hexWithHashtag;
        isWork = hasTag "users:craig:work";
        dmsPackage = inputs.dux-shell.lib.mkDmsShell pkgs;
        mkPlugin =
          {
            owner,
            repo,
            rev,
            hash,
            path ? null,
          }:
          let
            source = pkgs.fetchFromGitHub {
              inherit
                owner
                repo
                rev
                hash
                ;
            };
          in
          if path == null then
            source
          else
            pkgs.runCommand "dms-${repo}-${path}" { } ''
              mkdir -p "$out"
              cp -r ${source}/${path}/. "$out/"
            '';
        dankKDEConnectSrc = mkPlugin {
          owner = "duxlabs-dev";
          repo = "dux-plugins";
          path = "DankKDEConnect";
          rev = "b827c2296cd45a73bf9318f16a261c9edeec8339";
          hash = "sha256-OYCjryGkZ9DlMSS0DlaKzA/qRxXI+cAbO3uee+9Y+Kg=";
        };
        dankscaleSrc = mkPlugin {
          owner = "dwright134";
          repo = "dms-dankscale";
          rev = "bddebf0e2935ba23b0614ff9af5bf8f4ed6d3d9f";
          hash = "sha256-o5kcFV7VAmHJqsKgnjDuuryubnuI9U+GQIPOlENZ5ao=";
        };
        herdrAgentMonitorSrc = mkPlugin {
          owner = "Mor-dev";
          repo = "herdr-agent-monitor";
          rev = "c6b731ba9f00c37deef04b1e70251fb1b729c1df";
          hash = "sha256-58dZiKCDCTcVm5SAoEhOz19xuYB2paJ/85h5j29Uq1g=";
        };
        homeAssistantMonitorSrc = mkPlugin {
          owner = "xxyangyoulin";
          repo = "dms-plugin-hass";
          rev = "60593eccfad53d987e3520d8c040d6f8a1c31acd";
          hash = "sha256-LweJ+ccXtoG+P27ZI0rAaTacyz/w6pQSQov6eQMIjrM=";
        };
        quickCaptureSrc = mkPlugin {
          owner = "hthienloc";
          repo = "dms-plugins";
          path = "quickCapture";
          rev = "afcf5b73be5d09b801b50d31717dfc03fb4596e7";
          hash = "sha256-vbfZaAOyMcYVp3Xf1WR1REOc6rVCh8Ou9x6bt/EReFI=";
        };
        warpToggleSrc = mkPlugin {
          owner = "ahmed-mekky";
          repo = "dms-warp-toggle";
          rev = "3bee1e952c626071167c4e0aedad6241f7f624e0";
          hash = "sha256-SgUWuMG5bDuFbdXvWmSUfgOyiq2kX/6iovUIWITDxsE=";
        };
        dms = wrap.package {
          package = dmsPackage;

          runtimeInputs = [
            pkgs.gpu-screen-recorder
            pkgs.wf-recorder
            pkgs.ffmpeg
            pkgs.imagemagick
            pkgs.img2pdf
            pkgs.tesseract
            pkgs.zbar
            pkgs.curl
            pkgs.jq
            pkgs.sqlite
            pkgs.cava
            pkgs.kdePackages.kdeconnect-kde
            pkgs.valent
            pkgs.tailscale
          ]
          ++ lib.optional isWork pkgs.cloudflare-warp;
        };
        theme = pkgs.formats.json { };
        themeFile = theme.generate "hdwlinux-dms.json" {
          name = "hdwlinux";
          dark = {
            primary = colors.base0E;
            primaryText = colors.base00;
            primaryContainer = colors.base02;
            secondary = colors.base0D;
            surface = colors.base00;
            surfaceText = colors.base05;
            surfaceVariant = colors.base01;
            surfaceVariantText = colors.base04;
            surfaceTint = colors.base0E;
            background = colors.base00;
            backgroundText = colors.base05;
            outline = colors.base03;
            surfaceContainerLowest = colors.base11;
            surfaceContainerLow = colors.base01;
            surfaceContainer = colors.base02;
            surfaceContainerHigh = colors.base03;
            surfaceContainerHighest = colors.base04;
            error = colors.base08;
            warning = colors.base0A;
            info = colors.base0C;
            matugen_type = "scheme-tonal-spot";
          };
        };
        dmsOverview = pkgs.writeShellScriptBin "dms-overview" ''
          set -eu
          if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
            exec ${dms}/bin/dms ipc call hypr toggleOverview
          fi
          exec ${pkgs.niri}/bin/niri msg action toggle-overview
        '';
      in
      {
        home.packages = [ dmsOverview ];

        programs.dank-material-shell = {
          enable = true;
          systemd.enable = true;
          package = dms;
          enableDynamicTheming = false;
          enableAudioWavelength = false;
          enableCalendarEvents = false;
          plugins = {
            dankKDEConnect.src = dankKDEConnectSrc;
            dankscale = {
              src = dankscaleSrc;
              settings.lastAccount = "craiggwilson@github";
            };
            herdrAgentMonitor.src = herdrAgentMonitorSrc;
            homeAssistantMonitor.src = homeAssistantMonitorSrc;
            quickCapture = {
              src = quickCaptureSrc;
              settings = {
                backgroundAutoApply = false;
                showToolbarBorder = false;
                doneAction = "clipboard";
              };
            };
          }
          // lib.optionalAttrs isWork {
            warpToggle = {
              src = warpToggleSrc;
              settings.enabled = false;
            };
          };
          settings = builtins.fromJSON (builtins.readFile ./settings.json) // {
            currentThemeName = "custom";
            customThemeFile = "${config.xdg.configHome}/dms/themes/hdwlinux-dms.json";
          };
        };

        xdg.configFile = lib.mkMerge [
          {
            "dms/themes/hdwlinux-dms.json".source = themeFile;

            # DMS's own plugin manager installs plugins as symlinks into
            # ~/.config/dms/plugins/.repos. Home Manager only auto-backs-up
            # non-symlink targets, so it aborts activation on those with
            # "would be clobbered". Force replacement of everything DMS owns.
            "dms/plugin_settings.json".force = true;
            "dms/settings.json".force = true;
          }
          (lib.mapAttrs' (
            name: _: lib.nameValuePair "dms/plugins/${name}" { force = true; }
          ) config.programs.dank-material-shell.plugins)
        ];

        systemd.user.services.dms.Unit.ConditionEnvironment = "HDWLINUX_SHELL=dux";
      };
  };
}
