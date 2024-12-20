{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.xdg;
  hasApp = name: builtins.hasAttr name config.hdwlinux.apps;
  desktopName =
    name:
    let
      dn = config.hdwlinux.apps.${name}.desktopName;
    in
    if dn != null then dn else lib.hdwlinx.getAppName config.hdwlinux.apps.${name};
in
{
  options.hdwlinux.xdg = {
    enable = lib.hdwlinux.mkEnableOption "xdg" true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ xdg-utils ];

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
      mime = {
        enable = true;
      };
      mimeApps =
        let
          documentViewer = desktopName "documentViewer";
          fileManager = desktopName "fileManager";
          imageViewer = desktopName "imageViewer";
          webBrowser = desktopName "webBrowser";
        in
        {
          enable = true;
          defaultApplications = lib.mkMerge [
            (lib.mkIf (hasApp "documentViewer") {
              "application/pdf" = documentViewer;
            })
            (lib.mkIf (hasApp "fileManager") {
              "inode/directory" = fileManager;
            })
            (lib.mkIf (hasApp "imageViewer") {
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
            (lib.mkIf (hasApp "webBrowser") {
              "text/html" = [ webBrowser ];
              "text/xml" = [ webBrowser ];
              "x-scheme-handler/http" = [ webBrowser ];
              "x-scheme-handler/https" = [ webBrowser ];
            })
          ];

          associations.added = lib.mkIf (hasApp "documentViewer") {
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
}
