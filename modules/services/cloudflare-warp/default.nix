{
  config.substrate.modules.services.cloudflare-warp = {
    tags = [ "users:craig:work" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [ cloudflare-warp ];

      systemd.services.cloudflare-warp = {
        description = "Cloudflare Zero Trust Client Daemon";
        documentation = [
          "https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/"
        ];
        after = [ "pre-network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.cloudflare-warp}/bin/warp-svc";
          DynamicUser = "no";
          CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE";
          AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE";
          StateDirectory = "cloudflare-warp";
          RuntimeDirectory = "cloudflare-warp";
          LogsDirectory = "cloudflare-warp";
          Restart = "always";
        };
      };
    };

    homeManager = {
      # The package ships an XDG autostart entry (Exec=systemctl --user start
      # warp-taskbar) that launches the GUI tray at login. Override it with
      # Hidden=true so warp-taskbar does not start; warp-cli and the noctalia
      # warp widget still work, and the GUI remains launchable on demand.
      xdg.configFile."autostart/com.cloudflare.WarpTaskbar.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Cloudflare Zero Trust
        Hidden=true
      '';
    };
  };
}

