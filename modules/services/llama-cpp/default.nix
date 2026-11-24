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

        # Unsloth's prebuilt bundles the CUDA 13.3 runtime with SM 120/121 kernels
        # for the GB10 and decodes looped MoE models up to 1.9x faster than
        # mainline llama.cpp; our nixpkgs pin predates Inkling 2 support.
        package = pkgs.stdenv.mkDerivation {
          pname = "llama-cpp";
          version = "b12649-mix-c7059d6";

          src = pkgs.fetchurl {
            url = "https://github.com/unslothai/llama.cpp/releases/download/b12649-mix-c7059d6/app-b12649-mix-c7059d6-linux-arm64-cuda13-portable.tar.gz";
            sha256 = "641f0e7ec5dd82d2654947a77fb0d29c089f13fb60420e3b5e540306df7dcfff";
          };

          dontUnpack = true;
          dontConfigure = true;
          dontBuild = true;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          installPhase = ''
            runHook preInstall
            mkdir -p $out
            tar -xzf $src -C $out
            wrapProgram $out/llama-server \
              --set GGML_BACKEND_PATH "$out/libggml-cuda.so" \
              --prefix LD_LIBRARY_PATH : "${
                lib.makeLibraryPath [
                  pkgs.cudaPackages.cuda_cudart
                  pkgs.cudaPackages.libcublas
                  pkgs.openssl
                  pkgs.stdenv.cc.cc.lib
                ]
              }:/run/opengl-driver/lib"
            runHook postInstall
          '';
        };

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
          // lib.optionalAttrs (builtins.length v.paths > 2) {
            # A third file is a speculative-decoding draft model (e.g. an EAGLE-3 head).
            model-draft = builtins.elemAt v.paths 2;
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
              ExecStart = "${package}/llama-server --host ${cfg.host} --port ${lib.toString cfg.port} --models-preset ${config.xdg.configHome}/llama-cpp/models.ini --models-max 4 --models-memory-margin 16384";
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
