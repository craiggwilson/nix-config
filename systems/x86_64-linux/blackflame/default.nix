{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./disko.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_6_17;

  hdwlinux = {
    services.system76-battery = {
      profile = "max_lifespan";
    };

    tags = [
      "audio:midi"
      "audio:production"
      "boot:systemd"
      # Having some issues with xdg-desktop-portal-hyprland
      #"cuda"
      "desktop:hyprland"
      "desktop:niri"
      "desktop:remote"
      "filesystem:nfs"
      "fonts"
      "gaming"
      "gui"
      "networking:tailscale"
      "personal"
      "programming"
      "printing"
      "raeford"
      "scanning"
      "security:passwordmanager"
      "users:craig"
      "v4l2loopback"
      "video:production"
      "virtualization:podman"
      "vnc"
    ];

    hardware = {
      fingerprint.enable = false;
      models.system76-serval-ws.enable = true;
      monitors.laptop = {
        vendor = "BOE";
        model = "0x0A1C";
        mode = "1920x1080@165.004Hz";
        scale = 1.0;
      };
    };
    outputProfiles = {
      laptop = {
        outputs = [
          {
            monitor = "laptop";
            enable = true;
            position = "0,0";
          }
        ];
      };
      docked = {
        outputs = [
          {
            monitor = "office-main";
            enable = true;
            position = "0,1440";
            workspaces = [ "3" ];
          }
          {
            monitor = "office-top";
            enable = true;
            position = "1290,0";
            workspaces = [ "1" ];
          }
          {
            monitor = "portable";
            enable = true;
            position = "1000,2880";
            workspaces = [ "2" ];
          }
          {
            monitor = "laptop";
            enable = false;
          }
        ];
      };
      docked-no-portable = {
        outputs = [
          {
            monitor = "office-main";
            enable = true;
            position = "0,1440";
            workspaces = [
              "2"
              "3"
            ];
          }
          {
            monitor = "office-top";
            enable = true;
            position = "1290,0";
            workspaces = [ "1" ];
          }
          {
            monitor = "laptop";
            enable = false;
          }
        ];
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
