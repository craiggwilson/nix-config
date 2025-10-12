{
  description = "HDW Linux";

  inputs = {
    # unstable packages are used by default
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # also provide stable packages if unstable are breaking
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    # nix user repository provides additional packages.
    nur.url = "github:nix-community/NUR";

    # Generate System Images
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    # disko handles partitioning and applying disk configurations
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home manager for config files and user installs
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # kolide is a device management application for work.
    kolide-launcher = {
      url = "github:/kolide/nix-agent/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # musnix optimizes audio for realtime/production.
    musnix.url = "github:musnix/musnix";

    # nix-flatpak provides declaritive flatpak installation.
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.1.0";

    # nix-hardware helps set up machine configs
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # rust-overlay provides the latest rust packages
    rust-overlay.url = "github:oxalica/rust-overlay";

    # secrets is a private repository.
    secrets.url = "github:divnix/blank";

    # snowfall-lib provides structure to the flake
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # theming for spotify.
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;

        snowfall = {
          # access through the modules will be done through hdwlinux and lib.hdwlinux
          namespace = "hdwlinux";
          meta = {
            name = "hdwlinux";
            title = "Half-Dozen Wilsons Linux";
          };
        };
      };
    in
    lib.mkFlake {

      channels-config = {
        allowUnfree = true;

        permittedInsecurePackages = [
          # Required for proprietary applications that bundle older versions
          "electron-25.9.0" # Used by various Electron-based apps
        ];
      };

      formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

      overlays = with inputs; [
        nur.overlays.default
        rust-overlay.overlays.default
        (final: prev: {
          stable = import nixpkgs-stable {
            system = prev.system;
            config.allowUnfree = true;
          };
        })
      ];

      homes.modules = with inputs; [
        nix-flatpak.homeManagerModules.nix-flatpak
        spicetify-nix.homeManagerModules.default
      ];

      systems.modules.nixos = with inputs; [
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        musnix.nixosModules.musnix
        kolide-launcher.nixosModules.kolide-launcher
        ./nixos/craig
      ];
    };
}
