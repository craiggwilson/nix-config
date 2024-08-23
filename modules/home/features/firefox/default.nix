{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.features.firefox;
in
{
  options.hdwlinux.features.firefox = {
    enable = lib.hdwlinux.mkEnableOpt [ "gui" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      profiles."default" = {
        id = 0;
        name = "default";
        isDefault = true;
        settings = {
          "browser.disableResetPrompt" = true;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.startup.homepage" = "https://www.raeford.wilsonfamilyhq.com/";
          "browser.toolbars.bookmarks.visibility" = "always";
          "privacy.trackingprotection.enabled" = true;
          "signon.rememberSignons" = false;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "trailhead.firstrun.didSeeAboutWelcome" = true;
        };

        # containers = {
        #   "Personal" = {
        #     id = 1;
        #     color = "blue";
        #     icon = "fingerprint";
        #   };
        #   "Work" = {
        #     id = 2;
        #     color = "orange";
        #     icon = "briefcase";
        #   };
        #   "Banking" = {
        #     id = 3;
        #     color = "green";
        #     icon = "dollar";
        #   };
        #   "Heather" = {
        #     id = 4;
        #     color = "pink";
        #     icon = "cart";
        #   };
        #   "Local" = {
        #     id = 5;
        #     color = "red";
        #     icon = "fence";
        #   };
        # };

        userChrome = ''
          #main-window #titlebar {
            overflow: hidden;
            transition: height 0.3s 0.3s !important;
          }
          /* Default state: Set initial height to enable animation */
          #main-window #titlebar { height: 3em !important; }
          #main-window[uidensity="touch"] #titlebar { height: 3.35em !important; }
          #main-window[uidensity="compact"] #titlebar { height: 2.7em !important; }
          /* Hidden state: Hide native tabs strip */
          #main-window[titlepreface*="XXX"] #titlebar { height: 0 !important; }
          /* Hidden state: Fix z-index of active pinned tabs */
          #main-window[titlepreface*="XXX"] #tabbrowser-tabs { z-index: 0 !important; }
        '';

        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          multi-account-containers
          musescore-downloader
          onepassword-password-manager
          sidebery
          temporary-containers
          user-agent-string-switcher
        ];
      };
    };

    xdg.mimeApps.defaultApplications = {
      "application/pdf" = "firefox.desktop";
      "text/html" = [ "firefox.desktop" ];
      "text/xml" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
    };
  };
}
