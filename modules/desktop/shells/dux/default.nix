{
  config.substrate.modules.desktop.shells.dux = {
    tags = [ "desktop:shells:dux" ];

    nixos = {
      hdwlinux.desktop.shells.dux.prettyName = "Dux";
    };

    homeManager =
      {
        config,
        host,
        inputs,
        lib,
        pkgs,
        wrap,
        hasTag,
        ...
      }:
      let
        colors = config.hdwlinux.theme.colors.hexWithHashtag;
        isWork = hasTag "user:craig" && hasTag "profile:work";
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
        castSrc = mkPlugin {
          owner = "Conava";
          repo = "dux-plugins";
          path = "Cast";
          rev = "9763ee8c8d97d1731f57e886f91ce306f495cd67";
          hash = "sha256-zlzR2G2cW+VLE2ONzP59zWZFVAkYaYBgP416U3GgVSM=";
        };
        dankKDEConnectSrc = mkPlugin {
          owner = "duxlabs-dev";
          repo = "dux-plugins";
          path = "DankKDEConnect";
          rev = "e06aa40b1cb2b9ce50d3ee75f2874af05ae1763f";
          hash = "sha256-ksqeIRE5dZrbCXPr1p35aJd0ZLLEV926Tv8cJDtaPok=";
        };
        dankscaleSrc = mkPlugin {
          owner = "dwright134";
          repo = "dms-dankscale";
          rev = "fb21277e45a2c77eeb53de48a2008f07ea6892aa";
          hash = "sha256-YyFdgds1XBBVo4RYJTpK6z/U35vyEV01vYFoyTNM98M=";
        };
        herdrAgentMonitorSrc = mkPlugin {
          owner = "Mor-dev";
          repo = "herdr-agent-monitor";
          rev = "9474c46444600d5d39da16c7cc3239861834b6e3";
          hash = "sha256-e1lJs22k9UtzbozyMOn6V1PUDwCjpHt+/W8IOZywRwk=";
        };
        homeAssistantMonitorSrc = mkPlugin {
          owner = "xxyangyoulin";
          repo = "dms-plugin-hass";
          rev = "f76224ead8de03b94fff5f4f1821fdd1279acb85";
          hash = "sha256-yyg1IkumcjyMxJ1aBR3/rnnxIrBpWDOR/pNKfeQ9wYg=";
        };
        openTrackerBarSrc = mkPlugin {
          owner = "wsmajt";
          repo = "OpenTrackerBar";
          rev = "a2fcb5c0e788185ac2d2828e4ed42de78c87073d";
          hash = "sha256-2yI30jIWn2fdiTU8LkQO2AzbJEBXn/iF8x4vOmuAE+E=";
        };
        quickCaptureSrc = mkPlugin {
          owner = "hthienloc";
          repo = "dms-plugins";
          path = "quickCapture";
          rev = "b7ec1d6cd0fa1d42cab7c2f5996305c34897275c";
          hash = "sha256-KTp5FB/QFIvbsVX00aQSO5/DGv5qeFzClbj63p4qUUg=";
        };
        warpToggleSrc = mkPlugin {
          owner = "ahmed-mekky";
          repo = "dms-warp-toggle";
          rev = "3bee1e952c626071167c4e0aedad6241f7f624e0";
          hash = "sha256-SgUWuMG5bDuFbdXvWmSUfgOyiq2kX/6iovUIWITDxsE=";
        };
        maskedemailSrc = ./plugins/maskedemail;
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
            pkgs.hdwlinux.cast-helper
            pkgs.hdwlinux.doubletake
            pkgs.gst_all_1.gstreamer
            pkgs.gst_all_1.gst-plugins-base
            pkgs.gst_all_1.gst-plugins-good
            pkgs.gst_all_1.gst-plugins-bad
            pkgs.gst_all_1.gst-libav
            pkgs.pipewire
            pkgs.libheif
            pkgs.pulseaudio
            pkgs.kdePackages.kdeconnect-kde
            pkgs.valent
            pkgs.tailscale
            config.programs.opencode.package
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
        home.packages = [
          dmsOverview
        ];

        programs.dank-material-shell = {
          enable = true;
          systemd.enable = true;
          package = dms;
          enableDynamicTheming = false;
          enableAudioWavelength = false;
          enableCalendarEvents = true;
          plugins = {
            cast = {
              src = castSrc;
              settings.audioTarget = "local";
            };
            dankKDEConnect.src = dankKDEConnectSrc;
            dankscale = {
              src = dankscaleSrc;
              settings.lastAccount = "craiggwilson@github";
            };
            herdrAgentMonitor.src = herdrAgentMonitorSrc;
            homeAssistantMonitor.src = homeAssistantMonitorSrc;
            openTrackerBar.src = openTrackerBarSrc;
            maskedemail.src = maskedemailSrc;
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
            warpToggle.src = warpToggleSrc;
          };
          settings = builtins.fromJSON (builtins.readFile ./${host}-settings.json) // {
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
        systemd.user.services.dcal.Unit.ConditionEnvironment = "HDWLINUX_SHELL=dux";

        programs.dank-calendar = {
          enable = true;
          systemd.enable = true;
        };
      };
  };
}
