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
      "llm"
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
      monitors = [
        {
          port = "eDP-1";
          width = 1920;
          height = 1080;
          x = 0;
          y = 1440;
          scale = 1;
        }
        {
          description = "Dell Inc. DELL S2721DGF 2WXSR83";
          workspace = "2";
          width = 2560;
          height = 1440;
          x = 0;
          y = 0;
          scale = 1;
        }
        {
          description = "Dell Inc. DELL S2721DGF DSWSR83";
          workspace = "3";
          width = 2560;
          height = 1440;
          x = 2560;
          y = 0;
          scale = 1;
        }
        {
          description = "Ancor Communications Inc MB169B+       AIC1643";
          workspace = "1";
          width = 1920;
          height = 1080;
          x = 1920;
          y = 1440;
          scale = 1;
          displaylink = true;
        }
      ];
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
