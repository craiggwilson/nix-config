{
  config.substrate.modules.programs.xdg = {
    tags = [ "desktop" ];
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        hasApp = name: config.hdwlinux.desktop.apps.${name} != null;
        getDesktopName =
          name:
          let
            app = config.hdwlinux.desktop.apps.${name};
          in
          if app.desktopName != null then app.desktopName else (lib.getName app.package) + ".desktop";
      in
      {
        home.packages = [ pkgs.xdg-utils ];

        xdg = {
          enable = true;
          configFile."mimeapps.list".force = true;
          userDirs = {
            enable = true;
            createDirectories = true;
            setSessionVariables = true;
            extraConfig = {
              PROJECTS = "${config.home.homeDirectory}/Projects";
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
                  "application/bzip2" = archiver;
                  "application/gzip" = archiver;
                  "application/vnd.rar" = archiver;
                  "application/x-7z-compressed" = archiver;
                  "application/x-7z-compressed-tar" = archiver;
                  "application/x-bzip" = archiver;
                  "application/x-bzip-compressed-tar" = archiver;
                  "application/x-bzip2" = archiver;
                  "application/x-bzip2-compressed-tar" = archiver;
                  "application/x-compress" = archiver;
                  "application/x-compressed-tar" = archiver;
                  "application/x-cpio" = archiver;
                  "application/x-gzip" = archiver;
                  "application/x-lha" = archiver;
                  "application/x-lzip" = archiver;
                  "application/x-lzip-compressed-tar" = archiver;
                  "application/x-lzma" = archiver;
                  "application/x-lzma-compressed-tar" = archiver;
                  "application/x-rar-compressed" = archiver;
                  "application/x-tar" = archiver;
                  "application/x-tarz" = archiver;
                  "application/x-xar" = archiver;
                  "application/x-xz" = archiver;
                  "application/x-xz-compressed-tar" = archiver;
                  "application/x-zip-compressed" = archiver;
                  "application/x-zstd-compressed-tar" = archiver;
                  "application/zip" = archiver;
                  "application/zstd" = archiver;
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
                  "image/svg+xml" = imageViewer;
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
