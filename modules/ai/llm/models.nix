{
  config.substrate.modules.ai.llm = {
    tags = [ "ai:llm" ];

    homeManager =
      { lib, ... }:
      let
        hfFile =
          {
            repo,
            name,
            sha256,
          }:
          {
            inherit name sha256;
            url = "https://huggingface.co/${repo}/resolve/main/${name}?download=true";
          };

        hfSingleGGUF =
          { name, sha256 }:
          let
            # org/repo-GGUF:quant
            parts = lib.split "/|-GGUF:" name;
            org = lib.elemAt parts 0;
            repo = lib.elemAt parts 2;
            quant = lib.elemAt parts 4;
          in
          hfFile {
            inherit sha256;
            repo = "${org}/${repo}";
            name = "${repo}-${quant}.gguf";
          };
      in
      {
        config.hdwlinux.ai.llm.models = {
          "Qwen3-4B-Instruct-2507-Q4_0" = {
            type = "gguf";
            categories = [
              "fast"
              "writer"
            ];
            priority = 0;
            settings = {
              opencode = {
                name = "Qwen 3 4B Q4 16K";
                reasoning = false;
                tool_call = true;
                limit = {
                  context = 16384;
                  output = 8192;
                };
              };
              llama-cpp = {
                ctx-size = 16384;
                n-gpu-layers = 33;
                flash-attn = false;

                temp = 0.6;
                top-p = 0.9;
                top-k = 40;
                repeat-penalty = 1.1;

                mlock = true;
                mmap = true;
              };
            };
            files = [
              (hfSingleGGUF {
                name = "unsloth/Qwen3-4B-Instruct-2507-GGUF:Q4_0";
                sha256 = "sha256-4LpnXYarJ3xhcBxnk2WbKugB2V4755FGTDIeb79hO+I=";
              })
            ];
          };
          "Qwen3-8B-GGUF-Q4_K_M" = {
            type = "gguf";
            categories = [
              "balanced"
              "writer"
            ];
            priority = 10;
            settings = {
              opencode = {
                name = "Qwen 3 8B Q4 40K";
                reasoning = false;
                tool_call = true;
                limit = {
                  context = 40960;
                  output = 8192;
                };
              };
              llama-cpp = {
                ctx-size = 40960;
                n-gpu-layers = 33;
                flash-attn = true;

                temp = 0.7;
                top-p = 0.8;
                top-k = 20;
                repeat-penalty = 1.05;

                mlock = true;
                mmap = true;
              };
            };
            files = [
              (hfSingleGGUF {
                name = "ggml-org/Qwen3-8B-GGUF:Q4_K_M";
                sha256 = "sha256-pn2HYztfXxkaW9EebTfKsYuc49Smr2hhVh6KdnNSCAs=";
              })
            ];
          };
          "Qwen3-Coder-30B-A3B-Instruct-Q8_0" = {
            type = "gguf";
            categories = [
              "coder"
              "analyst"
              "code-reviewer"
            ];
            priority = 10;
            settings = {
              opencode = {
                name = "Qwen3 Coder 30B Q8";
                reasoning = false;
                tool_call = true;
                limit = {
                  context = 262144;
                  output = 8192;
                };
              };
              llama-cpp = {
                ctx-size = 262144;
                n-gpu-layers = 49;
                flash-attn = true;

                temp = 0.7;
                top-p = 0.8;
                top-k = 20;
                repeat-penalty = 1.05;

                mlock = true;
                mmap = true;
              };
            };
            files = [
              (hfFile {
                repo = "ggml-org/Qwen3-Coder-30B-A3B-Instruct-Q8_0-GGUF";
                name = "qwen3-coder-30b-a3b-instruct-q8_0.gguf";
                sha256 = "sha256-8imT4pMYtbnsICb2tlgCpcqZs4q0hEqrg67YomzgD/Y=";
              })
            ];
          };
          "Qwen2.5-Coder-7B-Instruct-GGUF-Q4_K_M" = {
            type = "gguf";
            categories = [
              "coder"
              "fast"
            ];
            priority = 0;
            settings = {
              opencode = {
                name = "Qwen 2.5 Coder 7B Q4";
                reasoning = false;
                tool_call = true;
                limit = {
                  context = 32768;
                  output = 8192;
                };
              };
              llama-cpp = {
                ctx-size = 32768;
                n-gpu-layers = 33;
                flash-attn = false;

                temp = 0.7;
                top-p = 0.8;
                top-k = 20;
                repeat-penalty = 1.05;

                mlock = true;
                mmap = true;
              };
            };
            files = [
              (hfSingleGGUF {
                name = "Qwen/Qwen2.5-Coder-7B-Instruct-GGUF:Q4_K_M";
                sha256 = "sha256-UJKH94y01M9rOENzRzO5FLLBWOQ+Iqf0v16WOACJTTw=";
              })
            ];
          };
          "Qwen3-VL-4B-Instruct-GGUF-Q4_K_M" = {
            type = "gguf";
            categories = [
              "vision"
            ];
            priority = 5;
            settings = {
              opencode = {
                name = "Qwen 3 VL 4B Q4";
                reasoning = false;
                tool_call = true;
                limit = {
                  context = 262144;
                  output = 8192;
                };
              };
              llama-cpp = {
                ctx-size = 262144;
                n-gpu-layers = 33;
                flash-attn = true;

                temp = 0.7;
                top-p = 0.8;
                top-k = 20;
                repeat-penalty = 1.05;

                mlock = true;
                mmap = true;
              };
            };
            files = [
              (hfFile {
                repo = "Qwen/Qwen3-VL-4B-Instruct-GGUF";
                name = "Qwen3VL-4B-Instruct-Q4_K_M.gguf";
                sha256 = "sha256-ZjWMsYu2s7G2Z1qkEseojvAdIo9IEYTRNmjlIBxzCgo=";
              })
              (hfFile {
                repo = "Qwen/Qwen3-VL-4B-Instruct-GGUF";
                name = "mmproj-Qwen3VL-4B-Instruct-F16.gguf";
                sha256 = "sha256-JW86Q71CBf/vSNa5JxXh5wtbDprvBlIlhJZ1E6mYUzE=";
              })
            ];
          };
        };
      };
  };
}
