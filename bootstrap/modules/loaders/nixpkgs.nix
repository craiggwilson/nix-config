{ config, lib, ... }:
{
  config = {
    loaders.nixpkgs = {
      settings = {
        type = lib.types.submoduleWith {
          shorthandOnlyDefinesConfig = true;
          modules = [
            {
              options = {
                systems = lib.mkOption {
                  description = "The systems to build for.";
                  type = lib.types.listOf lib.types.str;
                  default = [ "x86_64-linux" ];
                };
                overlays = lib.mkOption {
                  description = "The overlays to apply to the nixpkgs instance.";
                  type = lib.types.listOf lib.types.raw;
                  default = config.custom.overlays;
                };
                config = lib.mkOption {
                  description = "The configuration to pass to the nixpkgs instance.";
                  type = lib.types.attrs;
                  default = { };
                };
              };
            }
          ];
        };
        default = { };
      };

      load =
        input:
        let
          lib' = import "${input.src}/lib";
          pkgs = lib.genAttrs input.settings.systems (
            system:
            let
              overlays = builtins.map (
                overlay:
                let
                  overlay' = if lib.isPath overlay then import overlay { lib = lib'; } else overlay;
                in
                overlay'
              ) input.settings.overlays;
            in
            import input.src {
              inherit overlays system;
              inherit (input.settings) config;
            }
          );
        in
        pkgs
        // {
          lib = lib';
        };
    };
  };
}
