{
  description = "HDW Linux";

  nixConfig = {
    extra-substituters = [ "https://vicinae.cachix.org" ];
    extra-trusted-public-keys = [ "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc=" ];
  };

  inputs = {
    # Personal projects. These will ultimately be normal github references when they are good enough
    # to not be changed so often.
    hdwlinux-private.url = "git+file:///home/craig/Projects/hdwlinux/nix-private";
    mestra = {
      url = "git+file:///home/craig/Projects/hdwlinux/mestra";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.substrate.follows = "substrate";
    };
    opencode-augment-provider = {
      url = "git+file:///home/craig/Projects/hdwlinux/opencode-augment-provider";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.substrate.follows = "substrate";
    };
    opencode-projects-plugin = {
      url = "git+file:///home/craig/Projects/hdwlinux/opencode-projects-plugin";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.substrate.follows = "substrate";
    };
    scribe = {
      url = "git+file:///home/craig/Projects/hdwlinux/scribe";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.substrate.follows = "substrate";
    };
    substrate = {
      url = "git+file:///home/craig/Projects/hdwlinux/substrate";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Regular remote flakes.

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    googleworkspace-cli = {
      url = "github:googleworkspace/cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    jail-nix.url = "sourcehut:~alexdavid/jail.nix";

    kolide-launcher = {
      url = "github:/kolide/nix-agent/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-scratchpad.url = "github:argosnothing/niri-scratchpad-rs";

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode = {
      url = "github:anomalyco/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    openspec = {
      url = "github:Fission-AI/OpenSpec";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opnix = {
      url = "github:craiggwilson/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.vicinae.follows = "vicinae";
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
        inputs.substrate.substrateModules.jail
        inputs.substrate.substrateModules.nixos
        inputs.substrate.substrateModules.overlays
        inputs.substrate.substrateModules.packages
        inputs.substrate.substrateModules.published-modules
        inputs.substrate.substrateModules.shells
        inputs.substrate.substrateModules.tags
        inputs.substrate.substrateModules.types
      ];

      substrate.settings = {
        packageNamespace = "hdwlinux";

        homeManagerModules = [
          inputs.mestra.homeManagerModules.default
          inputs.opencode-augment-provider.homeManagerModules.default
          inputs.opencode-projects-plugin.homeManagerModules.default
          inputs.scribe.homeManagerModules.default
          inputs.vicinae.homeManagerModules.default
        ];

        nixosModules = [
          inputs.disko.nixosModules.disko
        ];

        publish = {
          packages = [
            ./packages/atlas-cli.nix
            ./packages/auggie.nix
            ./packages/code42-aat.nix
            ./packages/context7-mcp.nix
            ./packages/engflow_auth.nix
            ./packages/evergreen.nix
            ./packages/evergreen-mcp-server.nix
            ./packages/falcon-sensor.nix
            ./packages/fern.nix
            ./packages/mcp-atlassian.nix
            ./packages/monocle.nix
            ./packages/mongo-orchestration.nix
            ./packages/songtool.nix
            ./packages/writeShellApplicationWithSubcommands.nix
          ];

          shells = [
            ./shells/automation
            ./shells/go
            ./shells/hdwlinux
            ./shells/mms
            ./shells/mongotune
            ./shells/observability
            ./shells/rust
            ./shells/typescript
          ];
        };

        overlays = [
          # mestra — exposes pkgs.mestra.{mestra,opencode-plugin,skill}
          inputs.mestra.overlays.packages

          # scribe — exposes pkgs.scribe.scribe
          inputs.scribe.overlays.packages

          # NUR (Nix User Repository)
          inputs.nur.overlays.default

          # Rust overlay for rust-bin
          inputs.rust-overlay.overlays.default

          # Stable nixpkgs for packages not in unstable
          (final: prev: {
            stable = import inputs.nixpkgs-stable {
              system = final.stdenv.hostPlatform.system;
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
              "cuda"
              "printing"
              "raeford"
              "scanning"
            ];
          }

          # User-specific tags
          {
            "users:craig" = [
              "ai:clients"
              "cloud:sync"
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
              #"audio:midi"
              "ai:llm"
              "audio:production"
              "filesystem:nfs"
              "flatpaks"
              "gaming"
              "virtualization:podman"
            ];
          }
          {
            "users:craig:work" = [
              "filesystem:envfs"
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
          "ai:clients"
          "ai:llm"
          "audio"
          "audio:midi"
          "audio:production"
          "bluetooth"
          "boot:systemd"
          "camera"
          "cloud:sync"
          "cuda"
          "desktop"
          { "desktop:custom" = [ "gui" ]; }
          "desktop:custom:hyprland"
          "desktop:custom:niri"
          "filesystem:envfs"
          "filesystem:nfs"
          "flatpaks"
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
