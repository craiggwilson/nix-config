{
  config.substrate.modules.services.llama-cpp = {
    tags = [ "ai:llm" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.hdwlinux.services.llama-cpp;

        package =
          (pkgs.llama-cpp.override {
            cudaSupport = true;
            rocmSupport = false;
            metalSupport = false;
            # Enable BLAS for optimized CPU layer performance (OpenBLAS)
            # This is crucial for models using split-mode or CPU offloading
            blasSupport = true;
          }).overrideAttrs
            (oldAttrs: {
              # Enable native CPU optimizations for massively better CPU performance
              # This enables AVX, AVX2, AVX-512, FMA, etc. for your specific CPU
              # NOTE: This is intentionally opposite of nixpkgs (which uses -DGGML_NATIVE=off
              # for reproducible builds). We sacrifice portability for faster CPU layers.
              cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
                "-DGGML_NATIVE=ON"
              ];

              # Disable Nix's NIX_ENFORCE_NO_NATIVE which strips -march=native flags
              # See: https://github.com/NixOS/nixpkgs/issues/357736
              # See: https://github.com/NixOS/nixpkgs/pull/377484 (intentionally contradicts this)
              preConfigure = ''
                export NIX_ENFORCE_NO_NATIVE=0
                ${oldAttrs.preConfigure or ""}
              '';
            });

        presets = {
          "*" = {
            batch-size = 8096;
          };
        }
        // lib.mapAttrs (
          n: v:
          {
            model = lib.head v.paths;
          }
          // (v.settings.llama-cpp or { })
        ) config.hdwlinux.ai.llm.models;
      in
      {
        options.hdwlinux.services.llama-cpp = {
          host = lib.mkOption {
            description = "The host for llama-server.";
            type = lib.types.str;
            default = "127.0.0.1";
          };
          port = lib.mkOption {
            description = "The port for llama-server.";
            type = lib.types.int;
            default = 9292;
          };
        };
        config = {
          xdg.configFile."llama-cpp/models.ini".text = lib.generators.toINI { } presets;

          systemd.user.services.llama-cpp = {
            Unit = {
              Description = "LLaMA C++ server";
              Documentation = "https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md";
              After = [ "network.target" ];
            };
            Install = {
              WantedBy = [ "default.target" ];
            };
            Service = {
              Type = "idle";
              ExecStart = "${lib.getExe' package "llama-server"} --host ${cfg.host} --port ${lib.toString cfg.port} --models-preset ${config.xdg.configHome}/llama-cpp/models.ini";
              Restart = "on-failure";
              RestartSec = 300;
              TimeoutStopSec = 60;
              KillSignal = "SIGINT";
            };
          };
        };
      };
  };
}
