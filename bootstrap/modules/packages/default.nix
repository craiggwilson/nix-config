{ lib, config, ... }:
let
  builders = lib.mapAttrsToList (name: builder: builder // { inherit name; }) config.builders;
in
{
  options = {
    packages = lib.mkOption {
      description = "A set of packages";
      default = { };
      type = lib.types.lazyAttrsOf (
        lib.types.submodule (
          { name, ... }@args:
          let
            package = {
              inherit name;
              inherit (args.config)
                systems
                builder
                settings
                src
                ;
            };

            matching = builtins.filter (builder: package.builder == builder.name) builders;
            first = builtins.head matching;
            builder =
              if builtins.length matching == 0 then
                null
              else if builtins.length matching > 1 then
                builtins.trace "Warning: Multiple builders found for package \"${name}\", using first available: \"${first.name}\"" first
              else
                first;

            settings =
              if !(builtins.isNull builder) && builder.settings.type.check package.settings then
                package.settings
              else
                null;

            validity =
              if builtins.isNull builder then
                {
                  message = "No builder found for package \"${name}\" with builder \"${package.builder}\".";
                }
              else if builtins.isNull settings then
                {
                  message = "Invalid settings for builder \"${builder.name}\".";
                }
              else
                null;

            result = if builtins.isNull validity then builder.build package else null;
          in
          {
            options = {
              builder = lib.mkOption {
                description = "The builder to use for the package.";
                type = lib.types.str;
                default = "nixpkgs";
              };
              settings = lib.mkOption {
                description = "The settings to pass to the builder.";
                type = builder.settings.type;
                default = builder.settings.default;
              };
              src = lib.mkOption {
                description = "The package to build.";
                type = lib.types.raw;
              };
              systems = lib.mkOption {
                description = "The systems to build for.";
                type = lib.types.listOf lib.types.str;
                default = [ builtins.currentSystem ];
              };

              valid = lib.mkOption {
                description = "Whether the package is valid.";
                type = lib.types.raw;
                readOnly = true;
                default =
                  if builtins.isNull validity then
                    {
                      value = true;
                      message = "";
                    }
                  else
                    {
                      value = false;
                      message =
                        validity.message
                          or "Package \"${name}\" failed to load due to either invalid settings or an invalid builder.";
                    };
              };

              result = lib.mkOption {
                description = "The result of building the package.";
                type = lib.types.attrsOf lib.types.package;
                readOnly = true;
                default = result;
              };
            };
          }
        )
      );
    };
  };

  config = {
    # Add an overlay that makes custom packages available in pkgs
    overlays = lib.mkBefore [
      (
        final: prev:
        builtins.mapAttrs (
          name: pkg:
          pkg.result.${final.system}
            or (builtins.throw "Package \"${name}\" is not available for system \"${final.system}\"")
        ) config.packages
      )
    ];
  };
}
