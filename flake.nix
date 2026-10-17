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
    # Personal projects. These will ultimately be normal github references when they are good enough
    # to not be changed so often.
    hdwlinux-private.url = "git+file:///home/craig/Projects/hdwlinux/nix-private";
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
      url = "github:anomalyco/opencode";
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
        inputs.substrate.substrateModules.capabilities
        inputs.substrate.substrateModules.home-manager
        inputs.substrate.substrateModules.nixos
        inputs.substrate.substrateModules.overlays
        inputs.substrate.substrateModules.packages
        inputs.substrate.substrateModules.published-modules
        inputs.substrate.substrateModules.secrets
        inputs.substrate.substrateModules.shells
        # The tags extension still declares `extraModuleOptions.tags` and
        # neighbors the modulesFinder enum without which substrate's module
        # tree renders an endless type description (see /tmp/opencode/caps/rep
        # for the standalone repro). Both are dropped once substrate gains a
        # conversions-free extension.
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

          # Stable nixpkgs for packages not in unstable
          (final: _prev: {
            stable = import inputs.nixpkgs-stable {
              system = final.stdenv.hostPlatform.system;
              config.allowUnfree = true;
            };
          })
        ];
        modulesFinder = inputs.nixpkgs.lib.mkForce "by-capabilities";

      };
    };
}
