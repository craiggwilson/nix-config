{
  # Allow self-reference for recursive imports
  self ? (import ./. { }),
  # Load inputs from npins (non-flake dependency management)
  inputs ? (import ./npins),
  # Default to nixpkgs-unstable
  nixpkgs ? inputs.nixpkgs-unstable,
  # Support system override
  system ? "x86_64-linux",
  ...
}@args:
let
  # Load raw inputs from npins
  rawInputs = if args ? inputs then args.inputs else (import ./npins);

  # Use flake-compat to import flakes properly
  flakeCompat = import rawInputs.flake-compat;

  # Import flakes using flake-compat
  diskoFlake = (flakeCompat { src = rawInputs.disko; }).defaultNix;
  homeManagerFlake = (flakeCompat { src = rawInputs.home-manager; }).defaultNix;
  kolideFlake = (flakeCompat { src = rawInputs.kolide-launcher; }).defaultNix;
  musnixFlake = (flakeCompat { src = rawInputs.musnix; }).defaultNix;
  nixFlatpakFlake = (flakeCompat { src = rawInputs.nix-flatpak; }).defaultNix;
  nixosHardwareFlake = (flakeCompat { src = rawInputs.nixos-hardware; }).defaultNix;
  opnixFlake = (flakeCompat { src = rawInputs.opnix; }).defaultNix;
  spicetifyFlake = (flakeCompat { src = rawInputs.spicetify-nix; }).defaultNix;

  # Create a compatibility layer for inputs to match flake structure
  inputs = rawInputs // {
    disko = diskoFlake;
    home-manager = homeManagerFlake;
    kolide-launcher = kolideFlake;
    musnix = musnixFlake;
    nix-flatpak = nixFlatpakFlake;
    nixos-hardware = nixosHardwareFlake;
    opnix = opnixFlake;
    spicetify-nix = spicetifyFlake;
  };

  # Supported systems
  systems = [ "x86_64-linux" ];

  # Common nixpkgs config
  nixpkgsConfig = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-25.9.0" # Used by various Electron-based apps
    ];
  };

  # Import nixpkgs without overlays to get base lib
  baseNixpkgs = import nixpkgs { system = "x86_64-linux"; };

  # Custom lib functions from lib directory
  customLib = baseNixpkgs.lib.extend (
    final: prev:
    let
      libDirs = builtins.readDir ./lib;
      libNames = builtins.filter (name: libDirs.${name} == "directory") (builtins.attrNames libDirs);

      libModules = builtins.map (name: import (./lib + "/${name}/default.nix") { lib = final; }) libNames;

      # Also load the main lib/default.nix
      mainLib = import ./lib/default.nix final;
    in
    {
      hdwlinux = builtins.foldl' (acc: mod: acc // mod) mainLib libModules;
    }
  );

  lib = customLib;

  # Load all overlays from the overlays directory
  loadOverlays =
    dir:
    let
      overlayDirs = builtins.readDir dir;
      overlayNames = builtins.filter (name: overlayDirs.${name} == "directory") (
        builtins.attrNames overlayDirs
      );
    in
    builtins.map (
      name:
      let
        overlayPath = dir + "/${name}/default.nix";
        overlayModule = import overlayPath;
        # All overlays in this repo follow the pattern: { args... }: final: prev: { ... }
        # So we always call the module with args to get the actual overlay function
        overlayFn = overlayModule {
          inherit lib;
          channels = { inherit nixpkgs; };
        };
      in
      overlayFn
    ) overlayNames;

  # Import stable nixpkgs
  mkStablePkgs =
    system:
    import inputs.nixpkgs-stable {
      inherit system;
      config = nixpkgsConfig;
    };

  # Load NUR overlay
  nurOverlay = import inputs.nur {
    nurpkgs = baseNixpkgs;
    pkgs = baseNixpkgs;
  };

  # Base overlays (without custom packages to avoid circular dependency)
  baseOverlays = [
    # External overlays
    (final: prev: {
      # Add stable packages
      stable = mkStablePkgs prev.system;
    })
    # NUR overlay
    nurOverlay.overlays.default or (final: prev: { })
    # Rust overlay
    (import inputs.rust-overlay)
    # Local overlays
  ]
  ++ loadOverlays ./overlays;

  # Import nixpkgs with base overlays for each system
  mkBasePkgs =
    system:
    import nixpkgs {
      inherit system;
      config = nixpkgsConfig;
      overlays = baseOverlays;
    };

  # Load all packages from the packages directory
  loadPackages =
    system:
    let
      pkgs = mkBasePkgs system;
      packageDirs = builtins.readDir ./packages;
      packageNames = builtins.filter (name: packageDirs.${name} == "directory") (
        builtins.attrNames packageDirs
      );
    in
    builtins.listToAttrs (
      builtins.map (name: {
        inherit name;
        value = pkgs.callPackage (./packages + "/${name}") { };
      }) packageNames
    );

  # Packages for a specific system
  packagesForSystem = system: loadPackages system;

  # All overlays including custom packages
  allOverlays = baseOverlays ++ [
    # Overlay to add custom packages under pkgs.hdwlinux
    (final: prev: {
      hdwlinux = (prev.hdwlinux or { }) // packagesForSystem prev.system;
    })
  ];

  # Import nixpkgs with all overlays for each system
  mkPkgs =
    system:
    import nixpkgs {
      inherit system;
      config = nixpkgsConfig;
      overlays = allOverlays;
    };

  # Load all shells from the shells directory
  loadShells =
    system:
    let
      pkgs = mkPkgs system;
      shellDirs = builtins.readDir ./shells;
      shellNames = builtins.filter (name: shellDirs.${name} == "directory") (
        builtins.attrNames shellDirs
      );
    in
    builtins.listToAttrs (
      builtins.map (name: {
        inherit name;
        value = pkgs.callPackage (./shells + "/${name}") { inherit inputs lib; };
      }) shellNames
    );

  # Load private flake if it exists
  privateFlakePath = /home/craig/Projects/github.com/craiggwilson/nix-private;
  hasPrivateFlake =
    builtins.pathExists privateFlakePath && builtins.pathExists (privateFlakePath + "/default.nix");
  privateFlake = if hasPrivateFlake then import privateFlakePath { } else null;

  # Create NixOS configuration
  mkNixosConfiguration =
    system: name: configuration:
    let
      # Load external modules from flake outputs
      externalModules = builtins.filter (m: m != null) [
        (
          if inputs ? disko && inputs.disko ? nixosModules && inputs.disko.nixosModules ? disko then
            inputs.disko.nixosModules.disko
          else
            null
        )
        (
          if
            inputs ? home-manager
            && inputs.home-manager ? nixosModules
            && inputs.home-manager.nixosModules ? home-manager
          then
            inputs.home-manager.nixosModules.home-manager
          else
            null
        )
        (
          if
            inputs ? kolide-launcher
            && inputs.kolide-launcher ? nixosModules
            && inputs.kolide-launcher.nixosModules ? kolide-launcher
          then
            inputs.kolide-launcher.nixosModules.kolide-launcher
          else
            null
        )
        (
          if inputs ? musnix && inputs.musnix ? nixosModules && inputs.musnix.nixosModules ? musnix then
            inputs.musnix.nixosModules.musnix
          else
            null
        )
        (
          if inputs ? opnix && inputs.opnix ? nixosModules && inputs.opnix.nixosModules ? default then
            inputs.opnix.nixosModules.default
          else
            null
        )
        (
          if hasPrivateFlake && privateFlake ? nixosModules && privateFlake.nixosModules ? nix-private then
            privateFlake.nixosModules.nix-private
          else
            null
        )
      ];
    in
    import "${nixpkgs}/nixos/lib/eval-config.nix" {
      inherit system;
      modules = [
        # Local modules
        ./modules/nixos
        # User configuration
        configuration
        # Configure nixpkgs with overlays
        {
          nixpkgs.overlays = allOverlays;
        }
      ]
      ++ externalModules;
      specialArgs = {
        inherit inputs lib;
        self = finalOutputs;
      };
    };

  # Create Home Manager configuration
  mkHomeConfiguration =
    system: name: configuration:
    let
      pkgs = mkPkgs system;
      # Load external modules from flake outputs
      externalModules = builtins.filter (m: m != null) [
        (
          if
            inputs ? nix-flatpak
            && inputs.nix-flatpak ? homeManagerModules
            && inputs.nix-flatpak.homeManagerModules ? nix-flatpak
          then
            inputs.nix-flatpak.homeManagerModules.nix-flatpak
          else
            null
        )
        (
          if
            inputs ? opnix && inputs.opnix ? homeManagerModules && inputs.opnix.homeManagerModules ? default
          then
            inputs.opnix.homeManagerModules.default
          else
            null
        )
        (
          if
            inputs ? spicetify-nix
            && inputs.spicetify-nix ? homeManagerModules
            && inputs.spicetify-nix.homeManagerModules ? default
          then
            inputs.spicetify-nix.homeManagerModules.default
          else
            null
        )
        (
          if
            hasPrivateFlake
            && privateFlake ? homeManagerModules
            && privateFlake.homeManagerModules ? nix-private
          then
            privateFlake.homeManagerModules.nix-private
          else
            null
        )
      ];
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        # Local modules
        ./modules/home
        # User configuration
        configuration
      ]
      ++ externalModules;
      extraSpecialArgs = {
        inherit inputs lib;
        self = finalOutputs;
      };
    };

  # Per-system outputs
  perSystemOutputs = builtins.listToAttrs (
    builtins.map (system: {
      name = system;
      value = {
        # Packages available as pkgs.hdwlinux.<name>
        packages = packagesForSystem system;

        # Development shells
        devShells = loadShells system;

        # Formatter
        formatter = (mkPkgs system).nixfmt-rfc-style;

        # Legacy packages (nixpkgs with overlays applied)
        legacyPackages = mkPkgs system;
      };
    }) systems
  );

  # Final outputs
  finalOutputs = {
    inherit self inputs lib;

    outPath = ./.;

    # Per-system outputs
    packages = builtins.mapAttrs (_: v: v.packages) perSystemOutputs;
    devShells = builtins.mapAttrs (_: v: v.devShells) perSystemOutputs;
    formatter = builtins.mapAttrs (_: v: v.formatter) perSystemOutputs;
    legacyPackages = builtins.mapAttrs (_: v: v.legacyPackages) perSystemOutputs;

    # Overlays
    overlays = {
      default = builtins.foldl' (
        acc: overlay: final: prev:
        (acc final prev) // (overlay final prev)
      ) (final: prev: { }) allOverlays;
    }
    // builtins.listToAttrs (
      builtins.map
        (name: {
          inherit name;
          value = import (./overlays + "/${name}/default.nix") {
            inherit lib;
            channels = { inherit nixpkgs; };
          };
        })
        (
          builtins.filter (name: (builtins.readDir ./overlays).${name} == "directory") (
            builtins.attrNames (builtins.readDir ./overlays)
          )
        )
    );

    # NixOS configurations
    nixosConfigurations = {
      unsouled = mkNixosConfiguration "x86_64-linux" "unsouled" ./systems/x86_64-linux/unsouled;
      blackflame = mkNixosConfiguration "x86_64-linux" "blackflame" ./systems/x86_64-linux/blackflame;
    };

    # Home Manager configurations
    homeConfigurations = {
      "craig@unsouled" = mkHomeConfiguration "x86_64-linux" "craig" ./homes/x86_64-linux/craig;
      "craig@blackflame" = mkHomeConfiguration "x86_64-linux" "craig" ./homes/x86_64-linux/craig;
    };

    # NixOS modules
    nixosModules = {
      default = ./modules/nixos;
      hdwlinux = ./modules/nixos;
    };

    # Home Manager modules
    homeModules = {
      default = ./modules/home;
      hdwlinux = ./modules/home;
    };
  };
in
finalOutputs
