{ inputs, ... }:
{
  config.substrate.modules.nix = {
    nixos =
      {
        config,
        lib,
        pkgs,
        hasTag,
        ...
      }:
      let
        cfg = config.hdwlinux.nix;
      in
      {
        options.hdwlinux.nix = {
          package = lib.mkOption {
            description = "Which nix package to use.";
            type = lib.types.package;
            default = pkgs.nixVersions.latest;
          };

          extra-substituters = lib.mkOption {
            description = "Extra substituters to configure (name -> public key).";
            type = lib.types.attrsOf lib.types.str;
            default = { };
          };
        };

        config = {
          environment.systemPackages = with pkgs; [
            cacert
            deploy-rs
            nixfmt
            nix-prefetch-git
          ];

          environment.variables = {
            NIXPKGS_ALLOW_UNFREE = "1";
          };

          nixpkgs = {
            flake = {
              setNixPath = true;
              setFlakeRegistry = true;
            };
          };

          programs.nix-ld.enable = true;

          system = {
            activationScripts.diff = ''
              if [[ -e /run/current-system ]]; then
                ${pkgs.nix}/bin/nix store diff-closures /run/current-system "$systemConfig"
              fi
            '';

            switch.enable = true;

            autoUpgrade = lib.mkIf (hasTag "users:craig:work") {
              enable = true;
              flake = config.hdwlinux.flake;
              allowReboot = false;
              dates = "Fri *-*-* 02:00:00";
              flags = [
                "-L"
                "--commit-lock-file"
              ];
            };
          };

          boot.tmp.useTmpfs = true;
          systemd = {
            shutdownRamfs.enable = false;
            services.nix-daemon = {
              environment.TMPDIR = "/var/tmp";
            };
          };
          users.users.root.hashedPassword = "*";

          nix = {
            package = cfg.package;

            channel.enable = false;

            registry = {
              nixpkgs.flake = inputs.nixpkgs;
              stable.flake = inputs.nixpkgs-stable;
              unstable.flake = inputs.nixpkgs;
            }
            // lib.optionalAttrs (config.hdwlinux.flake != null) {
              hdwlinux.to = {
                type = "path";
                path = config.hdwlinux.flake;
              };
            };

            settings = {
              experimental-features = "nix-command flakes";
              http-connections = 50;
              warn-dirty = false;
              log-lines = 50;
              sandbox = true;
              auto-optimise-store = true;
              trusted-users = [
                "root"
                "@wheel"
              ];
              allowed-users = [
                "root"
                "@wheel"
              ];
              keep-outputs = true;
              keep-derivations = true;
              download-buffer-size = 1073741824; # 1 GiB
              substituters = [
                "https://cache.nixos.org"
                "https://nix-community.cachix.org"
              ]
              ++ (lib.mapAttrsToList (name: _: name) cfg.extra-substituters);

              trusted-public-keys = [
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              ]
              ++ (lib.mapAttrsToList (_: value: value) cfg.extra-substituters);
            };

            gc = {
              automatic = true;
              dates = "weekly";
              options = "--delete-older-than 30d";
            };
          };
        };
      };
  };
}
