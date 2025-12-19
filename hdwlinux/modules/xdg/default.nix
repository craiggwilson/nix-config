{
  config.substrate.modules.xdg = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        hasApp = name: builtins.hasAttr name config.hdwlinux.apps;
        getDesktopName =
          name:
          let
            app = config.hdwlinux.apps.${name};
            dn = app.desktopName;
          in
          if dn != null then dn else (app.package.meta.mainProgram or (lib.getName app.package)) + ".desktop";
      in
      {
        home.packages = [ pkgs.xdg-utils ];

        xdg = {
          enable = true;
          configFile."mimeapps.list".force = true;
          userDirs = {
            enable = true;
            createDirectories = true;
            extraConfig = {
              XDG_PROJECTS_DIR = "${config.home.homeDirectory}/Projects";
            };
          };
          mime.enable = true;
          mimeApps =
            let
              archiver = if hasApp "archiver" then getDesktopName "archiver" else null;
              documentViewer = if hasApp "documentViewer" then getDesktopName "documentViewer" else null;
              fileManager = if hasApp "fileManager" then getDesktopName "fileManager" else null;
              imageViewer = if hasApp "imageViewer" then getDesktopName "imageViewer" else null;
              webBrowser = if hasApp "webBrowser" then getDesktopName "webBrowser" else null;
            in
            {
              enable = true;
              defaultApplications = lib.mkMerge [
                (lib.mkIf (archiver != null) {
                  "application/vnd.rar" = archiver;
                  "application/x-rar-compressed" = archiver;
                  "application/zip" = archiver;
                  "application/x-zip-compressed" = archiver;
                  "multipart/x-zip" = archiver;
                })
                (lib.mkIf (documentViewer != null) {
                  "application/pdf" = documentViewer;
                })
                (lib.mkIf (fileManager != null) {
                  "inode/directory" = fileManager;
                })
                (lib.mkIf (imageViewer != null) {
                  "image/avif" = imageViewer;
                  "image/bmp" = imageViewer;
                  "image/gif" = imageViewer;
                  "image/jpg" = imageViewer;
                  "image/jpeg" = imageViewer;
                  "image/png" = imageViewer;
                  "image/tiff" = imageViewer;
                  "image/webp" = imageViewer;
                  "image/vnd.microsoft.icon" = imageViewer;
                })
                (lib.mkIf (webBrowser != null) {
                  "text/html" = [ webBrowser ];
                  "text/xml" = [ webBrowser ];
                  "x-scheme-handler/http" = [ webBrowser ];
                  "x-scheme-handler/https" = [ webBrowser ];
                })
              ];

              associations.added = lib.mkIf (documentViewer != null) {
                "application/vnd.comicbook-rar" = documentViewer;
                "application/vnd.comicbook+zip" = documentViewer;
                "application/x-cb7" = documentViewer;
                "application/x-cbr" = documentViewer;
                "application/x-cbt" = documentViewer;
                "application/x-cbz" = documentViewer;
                "application/x-ext-cb7" = documentViewer;
                "application/x-ext-cbr" = documentViewer;
                "application/x-ext-cbt" = documentViewer;
                "application/x-ext-cbz" = documentViewer;
                "application/x-ext-djv" = documentViewer;
                "application/x-ext-djvu" = documentViewer;
                "image/vnd.djvu" = documentViewer;
                "application/pdf" = documentViewer;
                "application/x-bzpdf" = documentViewer;
                "application/x-ext-pdf" = documentViewer;
                "application/x-gzpdf" = documentViewer;
                "application/x-xzpdf" = documentViewer;
                "application/postscript" = documentViewer;
                "application/x-bzpostscript" = documentViewer;
                "application/x-gzpostscript" = documentViewer;
                "application/x-ext-eps" = documentViewer;
                "application/x-ext-ps" = documentViewer;
                "image/x-bzeps" = documentViewer;
                "image/x-eps" = documentViewer;
                "image/x-gzeps" = documentViewer;
                "image/tiff" = documentViewer;
                "application/oxps" = documentViewer;
                "application/vnd.ms-xpsdocument" = documentViewer;
                "application/illustrator" = documentViewer;
              };
            };
        };
      };
  };
}
