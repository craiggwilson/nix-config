{
  config.substrate.modules.programs.firefox = {
    tags = [ "gui" ];

    # Provider mirrors for the perUser scope (app launcher + default-browser
    # resolution); the browser itself stays home-manager-side until its wave.
    # package duplicates the home-manager default on purpose:
    # config.programs.firefox.package is not visible here.
    perUser =
      { lib, pkgs, ... }:
      {
        hdwlinux.app.webBrowser = lib.mkDefault {
          package = pkgs.firefox;
          desktopName = "firefox.desktop";
        };

        hdwlinux.programs.browserctl.browsers.firefox = "firefox.desktop";
      };

    homeManager =
      { config, lib, pkgs, ... }:
      {
        hdwlinux.app.webBrowser = lib.mkDefault {
          package = config.programs.firefox.package;
          desktopName = "firefox.desktop";
        };

        hdwlinux.programs.browserctl.browsers.firefox = "firefox.desktop";

        programs.firefox = {
          enable = true;
          configPath = "${config.home.homeDirectory}/.mozilla/firefox";
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

            userChrome = ''
              #main-window .toolbar-items {
                overflow: hidden;
                transition: height 0.3s 0.3s !important;
              }
              #main-window .toolbar-items { height: 3em !important; }
              #main-window[uidensity="touch"] .toolbar-items { height: 3.35em !important; }
              #main-window[uidensity="compact"] .toolbar-items { height: 2.7em !important; }
              #main-window[titlepreface*="XXX"] .toolbar-items { height: 0 !important; }
              #main-window[titlepreface*="XXX"] #tabbrowser-tabs { z-index: 0 !important; }
            '';

            extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
              multi-account-containers
              musescore-downloader
              onepassword-password-manager
              sidebery
              temporary-containers
              user-agent-string-switcher
            ];
          };
        };
      };
  };
}
