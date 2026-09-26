{
  config.substrate.modules.xdg = {
    perUser =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        home = config.homeDirectory;

        userDirs = {
          DESKTOP = "Desktop";
          DOCUMENTS = "Documents";
          DOWNLOAD = "Downloads";
          MUSIC = "Music";
          PICTURES = "Pictures";
          PUBLICSHARE = "Public";
          TEMPLATES = "Templates";
          VIDEOS = "Videos";
          PROJECTS = "Projects";
        };

        userDirsFile = lib.concatStringsSep "\n" (
          lib.mapAttrsToList (k: v: ''XDG_${k}_DIR="${home}/${v}"'') userDirs
        ) + "\n";

        hasApp = name: config.hdwlinux.app.${name} != null;
        getDesktopName =
          name:
          let
            app = config.hdwlinux.app.${name};
          in
          if app.desktopName != null then app.desktopName else (lib.getName app.package) + ".desktop";

        # home-manager's emitter: each section is "[Name]" + entries,
        # sections separated by one blank line, file terminated by newline.
        renderMimeapps =
          sections:
          lib.concatStringsSep "\n\n" (
            lib.mapAttrsToList (
              section: entries:
              "[${section}]"
              + lib.concatStringsSep "" (
                lib.mapAttrsToList (
                  k: v:
                  "\n${k}=" + (if lib.isList v then lib.concatStringsSep ";" v else toString v)
                ) (lib.filterAttrs (_: v: v != null && v != [ ]) entries)
              )
            ) sections
          ) + "\n";

        archiverEntries = lib.genAttrs [
          "application/vnd.rar"
          "application/x-rar-compressed"
          "application/zip"
          "application/x-zip-compressed"
          "multipart/x-zip"
        ] (_: getDesktopName "archiver");

        documentViewerTypes = [
          "application/vnd.comicbook-rar"
          "application/vnd.comicbook+zip"
          "application/x-cb7"
          "application/x-cbr"
          "application/x-cbt"
          "application/x-cbz"
          "application/x-ext-cb7"
          "application/x-ext-cbr"
          "application/x-ext-cbt"
          "application/x-ext-cbz"
          "application/x-ext-djv"
          "application/x-ext-djvu"
          "image/vnd.djvu"
          "application/pdf"
          "application/x-bzpdf"
          "application/x-ext-pdf"
          "application/x-gzpdf"
          "application/x-xzpdf"
          "application/postscript"
          "application/x-bzpostscript"
          "application/x-gzpostscript"
          "application/x-ext-eps"
          "application/x-ext-ps"
          "image/x-bzeps"
          "image/x-eps"
          "image/x-gzeps"
          "image/tiff"
          "application/oxps"
          "application/vnd.ms-xpsdocument"
          "application/illustrator"
        ];

        imageViewerEntries = lib.genAttrs [
          "image/avif"
          "image/bmp"
          "image/gif"
          "image/jpg"
          "image/jpeg"
          "image/png"
          "image/tiff"
          "image/webp"
          "image/vnd.microsoft.icon"
        ] (_: getDesktopName "imageViewer");

        webBrowserEntries = lib.genAttrs [
          "text/html"
          "text/xml"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
        ] (_: [ (getDesktopName "webBrowser") ]);

        defaultApplications =
          (lib.optionalAttrs (hasApp "archiver") archiverEntries)
          // (lib.optionalAttrs (hasApp "documentViewer") {
            "application/pdf" = getDesktopName "documentViewer";
          })
          // (lib.optionalAttrs (hasApp "fileManager") {
            "inode/directory" = getDesktopName "fileManager";
          })
          // (lib.optionalAttrs (hasApp "imageViewer") imageViewerEntries)
          // (lib.optionalAttrs (hasApp "webBrowser") webBrowserEntries)
          // config.hdwlinux.xdg.defaultApplications;

        mimeapps = renderMimeapps {
          "Added Associations" =
            lib.optionalAttrs (hasApp "documentViewer") (
              lib.genAttrs documentViewerTypes (_: getDesktopName "documentViewer")
            );
          "Default Applications" = defaultApplications;
          "Removed Associations" = { };
        };
      in
      {
        options.hdwlinux.xdg.defaultApplications = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Extra Default Applications entries contributed by other modules.";
        };

        config = {
          packages = [ pkgs.xdg-utils ];

          files = {
            ".config/user-dirs.dirs".text = userDirsFile;
            ".config/mimeapps.list".text = mimeapps;
            # XDG spec: ~/.local/share/applications/mimeapps.list takes
            # precedence over ~/.config/mimeapps.list; the launcher scripts and
            # browserctl rewrite the effective copy at runtime.
            ".local/share/applications/mimeapps.list".text = mimeapps;
          };

          # Was xdg.userDirs.createDirectories: mkdir on session start, inert
          # once the directories exist.
          services.user-dirs-init = {
            description = "Create XDG user directories";
            wantedBy = [ "basic.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = lib.concatStringsSep "\n" (
              map (d: "mkdir -p ${lib.escapeShellArg "${home}/${d}"}") (lib.attrValues userDirs)
            );
          };
        };
      };
  };
}
