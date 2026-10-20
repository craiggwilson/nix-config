{
  description = "HDW Linux";

  nixConfig = {
    extra-substituters = [
      "https://vicinae.cachix.org"
      "https://mihakrumpestar.cachix.org"
      "https://noctalia.cachix.org"
    ];
    extra-trusted-public-keys = [
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "mihakrumpestar.cachix.org-1:7mKgpsk+9+iJcaT5DwvUtMxlJS+1GH/dlYhzoFkefJg="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  inputs = {
    # Personal projects. Fetched the same way on every machine; update the lock
    # with `nix flake update hdwlinux-private` after pushing to the remote.
    hdwlinux-private.url = "github:craiggwilson/nix-private";
    substrate = {
      url = "github:craiggwilson/substrate";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Regular remote flakes.

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    googleworkspace-cli = {
      url = "github:googleworkspace/cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:herdrdev/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    kolide-launcher = {
      url = "github:/kolide/nix-agent/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-scratchpad.url = "github:argosnothing/niri-scratchpad-rs";

    # Pinned to the cachix branch: always the latest cached build. Do not follow
    # nixpkgs here, or the derivation hash stops matching the binary cache.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode = {
      # Pinned to a dev rev: the v2.0.32 tag's nix packaging is broken (the
      # node_modules fileset omits the root script/ dir the cli build imports).
      # d85746a is dev with the fix; repin to a v2.0.33+ tag when one lands.
      url = "github:anomalyco/opencode/d85746a054924241a7edde736eefd079dff9bc00";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    openspec = {
      url = "github:Fission-AI/OpenSpec";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    panix = {
      url = "github:mihakrumpestar/panix";
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

    stable-diffusion-webui-nix = {
      url = "github:Janrupf/stable-diffusion-webui-nix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";

    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.vicinae.follows = "vicinae";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    inputs:
    inputs.substrate.build.with-flake-parts { inherit inputs; } {
      imports = [
        (inputs.import-tree ./modules)
        (inputs.import-tree ./packages)
        (inputs.import-tree ./shells)
        inputs.hdwlinux-private.substrateModules.nix-private
        inputs.substrate.substrateModules.home-manager
        inputs.substrate.substrateModules.nixos
        inputs.substrate.substrateModules.overlays
        inputs.substrate.substrateModules.packages
        inputs.substrate.substrateModules.published-modules
        inputs.substrate.substrateModules.secrets
        inputs.substrate.substrateModules.shells
        inputs.substrate.substrateModules.tags
        inputs.substrate.substrateModules.wrappers
        inputs.treefmt-nix.flakeModule
      ];

      perSystem = _: {
        treefmt.config = {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
          programs.deadnix.enable = true;
          programs.statix.enable = true;
        };
      };

      substrate.settings = {
        packages.namespace = "hdwlinux";

        # nixpkgs 26.11 dropped x86_64-darwin support, so the default
        # substrate system list fails to evaluate on that system.
        systems = [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-linux"
        ];

        nixpkgsConfig.allowUnfree = true;

        homeManager.modules = [
          inputs.noctalia.homeModules.default
          inputs.vicinae.homeManagerModules.default
          inputs.zen-browser.homeModules.default
        ];

        nixos.modules = [
          inputs.disko.nixosModules.disko
        ];

        overlays = [
          # NUR (Nix User Repository)
          inputs.nur.overlays.default

          # Rust overlay for rust-bin
          inputs.rust-overlay.overlays.default

          # Janrupf stable-diffusion-webui — exposes pkgs.stable-diffusion-webui.{forge,comfy}
          inputs.stable-diffusion-webui-nix.overlays.default

          # opencode v2 — exposes pkgs.opencode and pkgs.opencode-desktop from
          # the opencode flake instead of nixpkgs' 1.x
          inputs.opencode.overlays.default

          # Stable nixpkgs for packages not in unstable
          (final: _prev: {
            stable = import inputs.nixpkgs-stable {
              system = final.stdenv.hostPlatform.system;
              config.allowUnfree = true;
            };
          })
        ];
        tags.options = [
          # Host-specific tags
          "host:minimal"

          {
            "host:blackflame" = [
              "hardware:system76-serval-ws"

              "boot:systemd"
              "cuda"
              "networking:dns"
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
              "desktop:compositors:hyprland"
              "desktop:compositors:niri"
              "desktop:shells:noctalia"
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
              "ai:image"
              "ai:llm"
              "audio:production"
              "filesystem:nfs"
              "flatpaks"
              "gaming"
              "networking:tailscale"
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
          "ai:image"
          "ai:llm"
          "audio"
          "audio:midi"
          "audio:production"
          "bluetooth"
          "boot:systemd"
          "camera"
          "cloud:sync"
          "desktop:compositors:hyprland"
          "desktop:compositors:niri"
          "cuda"
          "desktop"
          "desktop:shells:custom"
          "desktop:shells:noctalia"
          "filesystem:envfs"
          "filesystem:nfs"
          "flatpaks"
          "fonts"
          { "gaming" = [ "desktop" ]; }
          "gaming:streaming"
          { "graphics" = [ "fonts" ]; }
          "graphics:nvidia"
          "laptop"
          "networking"
          "networking:dns"
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
