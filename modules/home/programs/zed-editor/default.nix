{
  config,
  lib,
  pkgs,
  flake,
  host,
  ...
}:
let
  cfg = config.hdwlinux.programs.zed-editor;
in
{
  options.hdwlinux.programs.zed-editor = {
    enable = config.lib.hdwlinux.mkEnableOption "zed-editor" [
      "programming"
      "gui"
    ];
  };

  config = lib.mkIf cfg.enable {

    programs.zed-editor = {
      enable = true;

      extraPackages = [
        pkgs.go
        pkgs.golangci-lint
        pkgs.nixd
      ];

      extensions = [
        "catppuccin"
        "golangci-lint"
        "gosum"
        "html"
        "nix"
      ];

      userSettings = {
        assistant = {
          default_model = {
            model = "o3-mini";
            provider = "copilot_chat";
          };
          version = "2";
        };
        languages = {
          Nix = {
            formatter = {
              external = {
                command = "nix";
                arguments = [
                  "fmt"
                  "--"
                  "--"
                ];
              };
            };
            language_servers = [
              "nixd"
              "!nil"
            ];
          };
          lsp = {
            nixd = {
              settings = {
                nixpkgs = {
                  expr = ''import (builtins.getFlake "${flake}").inputs.nixpkgs { }'';
                };

                formatting = {
                  command = [
                    "nix"
                    "fmt"
                    "--"
                    "--"
                  ];
                };
                options = {
                  enable = true;
                  nixos = {
                    expr = ''(builtins.getFlake "${flake}").nixosConfigurations.${host}.options'';
                  };
                  home-manager = {
                    expr = ''(builtins.getFlake "${flake}").homeConfigurations."${config.hdwlinux.user.name}@${host}".options'';
                  };
                };
                diagnostic = {
                  suppress = [ ];
                };
              };
            };
          };
          telemetry = {
            diagnostics = false;
            metrics = false;
          };
          theme = {
            dark = "Catppuccin Mocha";
            light = "Catppuccin Frappé";
            mode = "dark";
          };
        };
      };
    };
  };
}
