{
  config.substrate.modules.services.llama-cpp = {
    tags = [
      "service:ai:llm"
    ];

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
            blasSupport = false;
          }).overrideAttrs
            (_oldAttrs: {
              # Wintersteel's CUDA-enabled CTest suite failed during installation.
              doCheck = false;
            });

        presets = {
          "*" = {
            # Keep the load-time compute buffer small enough to fit 4B/7B models on GPU.
            batch-size = 1024;
          };
        }
        // lib.mapAttrs (
          _n: v:
          {
            model = lib.head v.paths;
          }
          // lib.optionalAttrs (builtins.length v.paths > 1) {
            mmproj = builtins.elemAt v.paths 1;
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
              # Keep 16 GiB available for the OS and non-LLM work while caching models.
              ExecStart = "${lib.getExe' package "llama-server"} --host ${cfg.host} --port ${lib.toString cfg.port} --models-preset ${config.xdg.configHome}/llama-cpp/models.ini --models-max 4 --models-memory-margin 16384";
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
