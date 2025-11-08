{ lib, config, ... }:
let
  loaders = lib.mapAttrsToList (name: loader: loader // { inherit name; }) config.loaders;
  customLoaders = builtins.filter (
    loader:
    !(builtins.elem loader.name [
      "flake"
      "legacy"
      "nixpkgs"
      "raw"
    ])
  ) loaders;
in
{
  options.inputs = lib.mkOption {
    description = "The inputs that are part of the project.";
    type = lib.types.lazyAttrsOf (
      lib.types.submodule (
        {
          name,
          ...
        }@args:
        let
          input = {
            inherit name;
            inherit (args.config) src loader settings;
          };

          matching = builtins.filter (loader: input.loader == loader.name) loaders;
          first = builtins.head matching;
          loader =
            if builtins.length matching == 0 then
              null
            else if builtins.length matching > 1 then
              builtins.trace "Warning: Multiple loaders found for input \"${name}\", using first available: \"${first.name}\"" first
            else
              first;

          settings =
            if !(builtins.isNull loader) && loader.settings.type.check input.settings then
              input.settings
            else
              null;

          validity =
            if builtins.isNull loader then
              {
                message = "No loader found for input \"${name}\" with loader \"${input.loader}\".";
              }
            else if builtins.isNull settings then
              {
                message = "Invalid settings for loader \"${loader.name}\".";
              }
            else
              null;

          result = if builtins.isNull validity then loader.load input else null;
        in
        {
          options = {
            src = lib.mkOption {
              description = "The source of the input.";
              type = lib.types.either lib.types.path lib.types.str;
              default = if builtins.hasAttr name config.pins then config.pins.${name} else null;
            };

            loader = lib.mkOption {
              description = "The loader to use for the input.";
              type = lib.types.str;
              default =
                let
                  contents = builtins.readDir args.config.src;
                  files = lib.filterAttrs (name: value: value == "regular") contents;
                  directories = lib.filterAttrs (name: value: value == "directory") contents;
                  symlinks = lib.filterAttrs (name: value: value == "symlink") contents;

                  matching = builtins.filter (loader: loader.check input) customLoaders;
                  loader = builtins.head matching;
                in
                if builtins.length matching != 0 then
                  loader.name
                else if
                  files ? "default.nix" && directories ? "pkgs" && directories ? "lib" && symlinks ? ".version"
                then
                  "nixpkgs"
                else if files ? "flake.nix" then
                  "flake"
                else if files ? "default.nix" then
                  "legacy"
                else
                  "raw";
            };

            settings = lib.mkOption {
              description = "The settings to pass to the loader.";
              type = loader.settings.type;
              default = loader.settings.default;
            };

            valid = lib.mkOption {
              description = "Whether the input is valid.";
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
                        or "Input \"${name}\" failed to load due to either invalid settings or an invalid loader.";
                  };
            };

            result = lib.mkOption {
              description = "The result of loading the input.";
              type = lib.types.raw;
              readOnly = true;
              default = result;
            };
          };
        }
      )
    );
  };

  config = {
    assertions = lib.mapAttrsToList (name: input: {
      assertion = input.valid.value;
      message = input.valid.message;
    }) config.inputs;
    inputs = builtins.mapAttrs (name: src: { src = src; }) config.pins;
  };
}
