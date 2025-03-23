{
  ...
}:
{
  imports = [
    ../../../hardware/dell-xps-15-9520.nix
    ./disko.nix
  ];

  hdwlinux = {
    tags = [
      "boot:systemd"
      "desktop:hyprland"
      "desktop:remote"
      "fonts"
      "gui"
      "networking:tailscale"
      "security:passwordmanager"
      "programming"
      "printing"
      "raeford"
      "scanning"
      "v4l2loopback"
      "video:production"
      "virtualization:docker"
      "work"
    ];

    hardware = {
      fingerprint.enable = false;
      monitors = {
        laptop = {
          vendor = "LG Display";
          model = "0x06B3";
          mode = "1920x1200@59.95Hz";
          scale = 1.0;
        };
        office-mounted-left = {
          vendor = "Dell Inc.";
          model = "DELL S2721DGF";
          serial = "DSWSR83";
          mode = "2560x1440@59.951Hz";
          scale = 1.0;
        };
        office-mounted-right = {
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
            monitor = "office-mounted-left";
            enable = true;
            position = "0,0";
            workspaces = [ "2" ];
          }
          {
            monitor = "office-mounted-right";
            enable = true;
            position = "2560,0";
            workspaces = [ "3" ];
          }
          {
            monitor = "portable";
            enable = true;
            position = "1920,1440";
            workspaces = [ "1" ];
          }
          {
            monitor = "laptop";
            enable = true;
            position = "5120,1440";
            workspaces = [ "0" ];
          }
        ];
      };
    };
  };

  boot.resumeDevice = "/dev/disk/by-uuid/451cd5d5-024b-4c13-9914-db4d4ab6c8db"; # findmnt -no UUID -T /.swapvol/swapfile
  boot.kernelParams = [
    "resume_offset=533760" # btrfs inspect-internal map-swapfile -r /.swapvol/swapfile
  ];
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=60m
    SuspendState=mem # suspend2idle is buggy :(
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
