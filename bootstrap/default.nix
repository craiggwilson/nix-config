# Bootstrap helper functions for building NixOS/Home Manager flakes.
# These are generic and not tied to any specific project name.
{ lib }:
let
  # The flake-parts modules that make up the bootstrap
  bootstrapModules = [
    ./options.nix
    ./overlays.nix
    ./perSystem.nix
    ./modules.nix
    ./systems.nix
    ./homes.nix
  ];

  bootstrap = {
    # Recursively find all directories containing default.nix under a base path.
    # Used for auto-discovering modules, packages, shells, and overlays.
    findModules =
      let
        go =
          basePath:
          let
            contents = if builtins.pathExists basePath then builtins.readDir basePath else { };
            hasDefaultNix = builtins.pathExists (basePath + "/default.nix");
            dirs = lib.filterAttrs (_: type: type == "directory") contents;
            subModules = lib.flatten (lib.mapAttrsToList (name: _: go (basePath + "/${name}")) dirs);
          in
          (if hasDefaultNix then [ basePath ] else [ ]) ++ subModules;
      in
      go;

    # Create a flake using bootstrap conventions.
    # Usage:
    #   outputs = inputs: (import ./bootstrap { inherit (inputs.nixpkgs) lib; }).mkFlake {
    #     inherit inputs;
    #     project = {
    #       lib = import ./myproject/lib { ... };
    #       overlays = bootstrap.findModules ./myproject/overlays;
    #       # ... other project options
    #     };
    #   };
    mkFlake =
      {
        # Required
        inputs,

        # Flake-parts options
        systems ? [ "x86_64-linux" ],
        extraModules ? [ ],

        # Project configuration
        project ? { },
      }:
      inputs.flake-parts.lib.mkFlake { inherit inputs; } {
        inherit systems;

        imports =
          bootstrapModules
          ++ extraModules
          ++ [
            inputs.home-manager.flakeModules.home-manager
          ]
          ++ [
            {
              inherit project;
            }
          ];
      };
  };
in
bootstrap
