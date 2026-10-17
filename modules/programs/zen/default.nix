{
  config.substrate.modules.programs.zen = {
    provides = [
      "programs:zen"
      "gui"
    ];
    requires = [ "gui" ];
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        programs.zen-browser = {
          enable = true;
          profiles."default" = {
            id = 0;
            name = "default";
            isDefault = true;

            extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
              musescore-downloader
              onepassword-password-manager
              user-agent-string-switcher
            ];
          };
        };

        hdwlinux.app.webBrowser = lib.mkDefault {
          package = config.programs.zen-browser.package;
          desktopName = "zen-beta.desktop";
        };

        hdwlinux.programs.browserctl.browsers.zen = "zen-beta.desktop";
      };
  };
}
