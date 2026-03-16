{
  config.substrate.modules.programs.browserctl = {
    tags = [ "gui" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.hdwlinux.programs.browserctl;

        # XDG spec: ~/.local/share/applications/mimeapps.list takes precedence over
        # ~/.config/mimeapps.list — Home Manager writes both, so we must update both.
        mimeappsPaths = [
          "${config.xdg.configHome}/mimeapps.list"
          "${config.home.homeDirectory}/.local/share/applications/mimeapps.list"
        ];

        # MIME types that identify the default web browser
        browserMimeTypes = [
          "text/html"
          "text/xml"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
        ];

        # sed -i args to replace the desktop file for each browser MIME type, all on one line
        setSedArgs =
          desktop:
          lib.concatMapStringsSep " " (mime: "-e 's|^${mime}=.*|${mime}=${desktop}|'") browserMimeTypes;

        # Shell snippet to replace a symlink with a writable copy and update browser entries
        applyToPath = desktop: path: ''
          if [[ -L "${path}" ]]; then
            readlink "${path}" > "${path}.nix-original"
            cp --no-preserve=mode "${path}" "${path}.tmp"
            mv "${path}.tmp" "${path}"
          fi
          sed -i ${setSedArgs desktop} "${path}"
        '';

        browserCase = lib.concatStringsSep "\n        " (
          lib.mapAttrsToList (name: desktop: ''
            ${name})
              ${lib.concatMapStringsSep "\n              " (applyToPath desktop) mimeappsPaths}
              echo "Default browser set to ${name}"
              ;;
          '') cfg.browsers
        );

        browserNames = lib.concatStringsSep ", " (lib.attrNames cfg.browsers);
      in
      {
        options.hdwlinux.programs.browserctl = {
          defaultBrowser = lib.mkOption {
            type = lib.types.str;
            default =
              let
                app = config.hdwlinux.apps.webBrowser or null;
              in
              if app != null then
                if app.desktopName != null then
                  app.desktopName
                else
                  (app.package.meta.mainProgram or (lib.getName app.package)) + ".desktop"
              else
                throw "hdwlinux.programs.browserctl.defaultBrowser: no webBrowser app configured and no explicit default set";
            description = "Desktop file name of the default browser, used by 'restore' to revert to the Nix-configured default.";
          };

          browsers = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            example = {
              chromium = "chromium.desktop";
              firefox = "firefox.desktop";
            };
            description = "Named browsers available to 'use'. Maps short name to desktop file name.";
          };
        };

        config.home.packages = [
          (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
            name = "browserctl";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.gnused
            ];
            subcommands = {
              use = ''
                case "''${1-}" in
                  ${browserCase}
                  "") echo "Usage: browserctl use <browser>"; echo "Available: ${browserNames}"; exit 1 ;;
                  *) echo "Unknown browser: $1"; echo "Available: ${browserNames}"; exit 1 ;;
                esac
              '';
              restore = ''
                restored=0
                ${lib.concatMapStringsSep "\n                " (path: ''
                  if [[ -f "${path}.nix-original" ]]; then
                    ln -sf "$(cat "${path}.nix-original")" "${path}"
                    rm "${path}.nix-original"
                    restored=1
                  fi
                '') mimeappsPaths}
                if [[ "$restored" -eq 1 ]]; then
                  echo "Restored default browser to ${cfg.defaultBrowser}"
                else
                  echo "No override active; nothing to restore"
                fi
              '';
              status = ''
                # Read from the highest-priority path
                status_path="${lib.last mimeappsPaths}"
                if [[ -f "$status_path.nix-original" ]]; then
                  echo "(overridden)"
                fi
                grep -E '^x-scheme-handler/https=' "$status_path" | cut -d= -f2
              '';
            };
          })
        ];
      };
  };
}
