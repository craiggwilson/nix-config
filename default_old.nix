# let
#   # Load inputs from npins
#   pins = import ./npins;

#   # Import nixpkgs without overlays to get base lib for utilities
#   baseNixpkgs = import pins.nixpkgs-unstable { system = "x86_64-linux"; };

#   # Load utility functions from top-level lib
#   util = import ./lib { lib = baseNixpkgs.lib; };

#   inputs = util.inputs.load pins;

#   # Use nixpkgs-unstable from inputs
#   nixpkgs = pins.nixpkgs-unstable;

#   # Supported systems
#   systems = [ "x86_64-linux" ];

#   # Common nixpkgs config
#   nixpkgsConfig = {
#     allowUnfree = true;
#     permittedInsecurePackages = [
#       "electron-25.9.0" # Used by various Electron-based apps
#     ];
#   };

#   # Custom lib functions from hdwlinux/lib directory
#   customLib = baseNixpkgs.lib.extend (
#     final: prev:
#     let
#       libDirs = builtins.readDir ./hdwlinux/lib;
#       libNames = builtins.filter (name: libDirs.${name} == "directory") (builtins.attrNames libDirs);

#       # Import all lib modules and flatten them
#       libModules = builtins.map (
#         name: import (./hdwlinux/lib + "/${name}/default.nix") { lib = final; }
#       ) libNames;

#       # Also load the main hdwlinux/lib/default.nix
#       mainLib = import ./hdwlinux/lib/default.nix final;
#     in
#     {
#       hdwlinux = builtins.foldl' (acc: mod: acc // mod) (mainLib // util) libModules;
#     }
#   );

#   lib = customLib;

#   # Import stable nixpkgs
#   mkStablePkgs = system: util.mkPkgs inputs.nixpkgs-stable system nixpkgsConfig [ ];

#   # Base overlays (without custom packages to avoid circular dependency)
#   baseOverlays = [
#     # External overlays
#     (final: prev: {
#       # Add stable packages
#       stable = mkStablePkgs prev.system;
#     })
#     # Rust overlay
#     (import inputs.rust-overlay)
#     # Local overlays
#   ]
#   ++ lib.hdwlinux.loadOverlays ./hdwlinux/overlays;

#   # Import nixpkgs with base overlays for each system
#   mkBasePkgs = system: util.mkPkgs nixpkgs system nixpkgsConfig baseOverlays;

#   # Packages for a specific system
#   packagesForSystem = system: lib.hdwlinux.loadPackages (mkBasePkgs system) ./hdwlinux/packages;

#   # All overlays including custom packages
#   allOverlays = baseOverlays ++ [
#     # Overlay to add custom packages under pkgs.hdwlinux
#     (final: prev: {
#       hdwlinux = (prev.hdwlinux or { }) // packagesForSystem prev.system;
#     })
#   ];

#   # Import nixpkgs with all overlays for each system
#   mkPkgs = system: util.mkPkgs nixpkgs system nixpkgsConfig allOverlays;

#   # Load private flake if it exists
#   privateFlakePath = /home/craig/Projects/github.com/craiggwilson/nix-private;
#   hasPrivateFlake =
#     builtins.pathExists privateFlakePath && builtins.pathExists (privateFlakePath + "/default.nix");
#   privateFlake = if hasPrivateFlake then import privateFlakePath { } else null;

#   # Create NixOS configuration
#   mkNixosConfiguration =
#     system: name: configuration:
#     let
#       # Load external modules from flake outputs
#       externalModules = [
#         inputs.disko.nixosModules.disko
#         inputs.home-manager.nixosModules.home-manager
#         inputs.kolide-launcher.nixosModules.kolide-launcher
#         inputs.musnix.nixosModules.musnix
#         inputs.opnix.nixosModules.default
#       ]
#       ++ lib.optional hasPrivateFlake privateFlake.nixosModules.nix-private;
#     in
#     import "${nixpkgs}/nixos/lib/eval-config.nix" {
#       inherit system;
#       modules = [
#         # Local modules
#         ./hdwlinux/modules/nixos
#         # User configuration
#         configuration
#         # Configure nixpkgs with overlays
#         {
#           nixpkgs.overlays = allOverlays;
#         }
#       ]
#       ++ externalModules;
#       specialArgs = {
#         inherit inputs lib;
#         self = finalOutputs;
#       };
#     };

#   # Create Home Manager configuration
#   mkHomeConfiguration =
#     system: name: configuration:
#     let
#       pkgs = mkPkgs system;
#       # Load external modules from flake outputs
#       externalModules = [
#         inputs.nix-flatpak.homeManagerModules.nix-flatpak
#         inputs.opnix.homeManagerModules.default
#         inputs.spicetify-nix.homeManagerModules.default
#       ]
#       ++ lib.optional hasPrivateFlake privateFlake.homeManagerModules.nix-private;
#     in
#     inputs.home-manager.lib.homeManagerConfiguration {
#       inherit pkgs;
#       modules = [
#         # Local modules
#         ./hdwlinux/modules/home
#         # User configuration
#         configuration
#       ]
#       ++ externalModules;
#       extraSpecialArgs = {
#         inherit inputs lib;
#         self = finalOutputs;
#       };
#     };

#   # Per-system outputs
#   perSystemOutputs = util.forAllSystems systems (system: {
#     # Packages available as pkgs.hdwlinux.<name>
#     packages = packagesForSystem system;

#     # Development shells
#     devShells = lib.hdwlinux.loadShells (mkPkgs system) inputs ./hdwlinux/shells;

#     # Formatter
#     formatter = (mkPkgs system).nixfmt-rfc-style;

#     # Legacy packages (nixpkgs with overlays applied)
#     legacyPackages = mkPkgs system;
#   });

#   # Final outputs
#   finalOutputs = {
#     # Self-reference for modules
#     self = finalOutputs;

#     # Expose inputs and lib
#     inherit inputs lib;

#     outPath = ./.;

#     # Per-system outputs
#     packages = util.extractPerSystem "packages" perSystemOutputs;
#     devShells = util.extractPerSystem "devShells" perSystemOutputs;
#     formatter = util.extractPerSystem "formatter" perSystemOutputs;
#     legacyPackages = util.extractPerSystem "legacyPackages" perSystemOutputs;

#     # Overlays
#     overlays = {
#       default = util.combineOverlays allOverlays;
#     }
#     // util.loadNamedOverlays ./hdwlinux/overlays;

#     # NixOS configurations
#     nixosConfigurations = {
#       unsouled = mkNixosConfiguration "x86_64-linux" "unsouled" ./hdwlinux/systems/x86_64-linux/unsouled;
#       blackflame =
#         mkNixosConfiguration "x86_64-linux" "blackflame"
#           ./hdwlinux/systems/x86_64-linux/blackflame;
#     };

#     # Home Manager configurations
#     homeConfigurations = {
#       "craig@unsouled" = mkHomeConfiguration "x86_64-linux" "craig" ./hdwlinux/homes/x86_64-linux/craig;
#       "craig@blackflame" = mkHomeConfiguration "x86_64-linux" "craig" ./hdwlinux/homes/x86_64-linux/craig;
#     };

#     # NixOS modules
#     nixosModules = {
#       default = ./hdwlinux/modules/nixos;
#       hdwlinux = ./hdwlinux/modules/nixos;
#     };

#     # Home Manager modules
#     homeModules = {
#       default = ./hdwlinux/modules/home;
#       hdwlinux = ./hdwlinux/modules/home;
#     };
#   };
# in
# finalOutputs
