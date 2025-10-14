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
      "audio"
      "bluetooth"
      "boot:systemd"
      "desktop:hyprland"
      "desktop:niri"
      "desktop:remote"
      "fonts"
      "gui"
      "laptop"
      "networking"
      "networking:tailscale"
      "nvidia"
      "programming"
      "printing"
      "raeford"
      "scanning"
      "security:passwordmanager"
      "users:craig"
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
