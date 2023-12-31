{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.firefox;
in
{
  options.hdwlinux.features.firefox = with types; {
    enable = mkEnableOpt ["gui"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
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
          "trailhead.firstrun.didSeeAboutWelcome" = true;
        };
      

        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          multi-account-containers
          musescore-downloader
          onepassword-password-manager
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
