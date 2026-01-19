{
  description = "HDW Linux";

  inputs = {
    hdwlinux-private.url = "git+file:///home/craig/Projects/github.com/craiggwilson/nix-private";

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    kolide-launcher = {
      url = "github:/kolide/nix-agent/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    musnix.url = "github:musnix/musnix";

    nirinit = {
      url = "github:amaanq/nirinit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-scratchpad = {
      url = "github:gvolpe/niri-scratchpad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.1.0";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    opnix = {
      url = "github:craiggwilson/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    substrate = {
      url = "path:../substrate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      ...
    }:
    inputs.substrate.build.with-flake-parts { inherit inputs; } {
      imports = [
        (inputs.import-tree ./modules)
        inputs.hdwlinux-private.substrateModules.nix-private
        inputs.substrate.substrateModules.home-manager
        inputs.substrate.substrateModules.shells
        inputs.substrate.substrateModules.tags
        inputs.substrate.substrateModules.types
      ];

      substrate.settings = {
        packageNamespace = "hdwlinux";
        packages = [
          ./packages/atlas-cli.nix
          ./packages/auggie.nix
          ./packages/code42-aat.nix
          ./packages/context7-mcp.nix
          ./packages/engflow_auth.nix
          ./packages/evergreen.nix
          ./packages/falcon-sensor.nix
          ./packages/fern.nix
          ./packages/mcp-atlassian.nix
          ./packages/mongo-orchestration.nix
          ./packages/slack-mcp-server.nix
          ./packages/songtool.nix
          ./packages/workspace-mcp.nix
          ./packages/writeShellApplicationWithSubcommands.nix
        ];

        shells = [
          ./shells/automation
          ./shells/go
          ./shells/mms
          ./shells/mongotune
          ./shells/observability
          ./shells/rust
        ];

        nixosModules = [
          inputs.disko.nixosModules.disko
        ];

        overlays = [
          # NUR (Nix User Repository)
          inputs.nur.overlays.default

          # Stable nixpkgs for packages not in unstable
          (final: prev: {
            stable = import inputs.nixpkgs-stable {
              inherit (final) system;
              config.allowUnfree = true;
            };
          })
        ];
        tags = [
          # Host-specific tags
          "host:minimal"

          {
            "host:blackflame" = [
              "hardware:system76-serval-ws"

              "boot:systemd"
              "cuda"
              "printing"
              "raeford"
              "scanning"
            ];
          }
          {
            "host:unsouled" = [
              "hardware:dell-xps-15-9520"

              "boot:systemd"
              "printing"
              "raeford"
              "scanning"
            ];
          }

          # User-specific tags
          {
            "users:craig" = [
              "ai:mcp"
              "desktop:custom:niri"
              "networking:tailscale"
              "programming"
              "security:passwordmanager"
              "security:secrets"
              "theming:catppuccin"
              "video:production"
              "yubikey"
            ];
          }
          {
            "users:craig:personal" = [
              "audio:midi"
              "audio:production"
              "filesystem:nfs"
              "gaming"
              "virtualization:podman"
            ];
          }
          {
            "users:craig:work" = [
              "virtualization:docker"
            ];
          }

          # Hardware model tags - imply common hardware features
          {
            "hardware:dell-xps-15-9520" = [
              "audio"
              "bluetooth"
              "camera"
              "graphics:nvidia"
              "laptop"
              "networking"
              "thunderbolt"
            ];
          }
          {
            "hardware:system76-serval-ws" = [
              "audio"
              "bluetooth"
              "camera"
              "graphics:nvidia"
              "laptop"
              "networking"
              "thunderbolt"
            ];
          }

          # Feature tags
          "ai:mcp"
          "audio"
          "audio:midi"
          "audio:production"
          "bluetooth"
          "boot:systemd"
          "camera"
          { "cuda" = [ "graphics:nvidia" ]; }
          "desktop"
          { "desktop:custom" = [ "gui" ]; }
          "desktop:custom:hyprland"
          "desktop:custom:niri"
          "filesystem:nfs"
          "fonts"
          { "gaming" = [ "gui" ]; }
          "gaming:streaming"
          "graphics"
          "graphics:nvidia"
          {
            "gui" = [
              "fonts"
              "graphics"
            ];
          }
          "laptop"
          "networking"
          "networking:tailscale"
          "printing"
          "programming"
          "raeford"
          "scanning"
          "security"
          "security:passwordmanager"
          "security:secrets"
          "theming"
          "theming:catppuccin"
          "thunderbolt"
          "v4l2loopback"
          "video"
          {
            "video:production" = [
              "v4l2loopback"
            ];
          }
          "virtualization"
          "virtualization:docker"
          "virtualization:podman"
          "virtualization:waydroid"
          "yubikey"
        ];
      };
    };
}
