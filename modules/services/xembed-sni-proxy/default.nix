{
  config.substrate.modules.services.xembed-sni-proxy = {
    tags = [ "gui" ];

    perUser =
      { config, pkgs, ... }:
      {
        # Mirrors home-manager's services.xembed-sni-proxy; the package lives
        # only in the unit's ExecStart closure (as before -- no profile entry).
        # HM's profileDirectory/bin maps to NixOS's per-user profile.
        services.xembed-sni-proxy = {
          description = "XEmbed SNI Proxy";
          wantedBy = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          unitConfig = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
            PartOf = [ "graphical-session.target" ];
          };
          serviceConfig = {
            Environment = [ "PATH=/etc/profiles/per-user/${baseNameOf config.homeDirectory}/bin" ];
            ExecStart = "${pkgs.kdePackages.plasma-workspace}/bin/xembedsniproxy";
            Restart = "on-abort";
          };
        };
      };
  };
}
