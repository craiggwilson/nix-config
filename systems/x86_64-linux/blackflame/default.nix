{
  ...
}:
{
  imports = [
    ../../../hardware/system76-serval-ws.nix
    ./disko.nix
  ];

  hdwlinux = {
    services.system76-battery = {
      profile = "max_lifespan";
    };

    tags = [
      "audio:midi"
      "audio:production"
      "boot:systemd"
      "cuda"
      "desktop:hyprland"
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
      "v4l2loopback"
      "video:production"
      "virtualization:podman"
      "vnc"
    ];

    hardware = {
      fingerprint.enable = false;
      monitors = {
        laptop = {
          vendor = "BOE";
          model = "0x0A1C";
          mode = "1920x1080@165.004Hz";
          scale = 1.0;
        };
        office-main = {
          vendor = "Samsung Electric Company";
          model = "Odyssey G95C";
          serial = "HNTY500018";
          mode = "5120x1440@59.977Hz";
          scale = 1.0;
        };
        office-top = {
          vendor = "Dell Inc.";
          model = "DELL S2721DGF";
          serial = "DSWSR83";
          mode = "2560x1440@59.951Hz";
          scale = 1.0;
        };
        portable = {
          vendor = "Ancor Communications Inc";
          model = "MB169B+      ";
          serial = "AIC1643";
          mode = "1920x1080@60.01Hz";
          scale = 1.0;
          displaylink = true;
        };
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
