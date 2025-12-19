{
  description = "HDW Linux";

  inputs = {
    # unstable packages are used by default
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # also provide stable packages if unstable are breaking
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    # flake-parts provides structure to the flake
    flake-parts.url = "github:hercules-ci/flake-parts";

    import-tree.url = "github:vic/import-tree";

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

    hdwlinux-private.url = "git+file:///home/craig/Projects/github.com/craiggwilson/nix-private";

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

    niri-scratchpad = {
      url = "github:gvolpe/niri-scratchpad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-flatpak provides declaritive flatpak installation.
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.1.0";

    # nix-hardware helps set up machine configs
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    opnix = {
      url = "github:craiggwilson/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # rust-overlay provides the latest rust packages
    rust-overlay.url = "github:oxalica/rust-overlay";

    # theming for spotify.
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules)
