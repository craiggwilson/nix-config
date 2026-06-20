{
  config.substrate.modules.ai.llm = {
    tags = [ "ai:llm" ];

    homeManager =
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

      in
      {
        config.hdwlinux.ai.llm.models = {
          "Qwen3-4B-Instruct-2507-Q4_0" = {
            type = "gguf";
            categories = [
              "fast"
              "writer"
            ];
            priority = 5;
            settings = {
              opencode = {
                name = "Qwen3 4B Instruct Q32K";
                reasoning = false;
                tool_call = true;
                limit = {
                  context = 32768;
                  output = 8192;
                };
              };
              llama-cpp = {
                ctx-size = 32768;
                flash-attn = false;
                parallel = 1;

                temp = 0.6;
                top-p = 0.9;
                top-k = 40;
                repeat-penalty = 1.1;

                mlock = true;
                mmap = true;
              };
            };
            files = [
              (hfFile {
                repo = "unsloth/Qwen3-4B-Instruct-2507-GGUF";
                name = "Qwen3-4B-Instruct-2507-Q4_0.gguf";
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
                name = "Qwen3 8B Instruct Q32K";
                reasoning = false;
                tool_call = true;
                limit = {
                  context = 32768;
                  output = 8192;
                };
              };
              llama-cpp = {
                ctx-size = 32768;
                flash-attn = false;
                parallel = 1;

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
                repo = "ggml-org/Qwen3-8B-GGUF";
                name = "Qwen3-8B-Q4_K_M.gguf";
                sha256 = "sha256-pn2HYztfXxkaW9EebTfKsYuc49Smr2hhVh6KdnNSCAs=";
              })
            ];
          };
          "Qwen3-4B-Thinking-2507-GGUF-Q8_0" = {
            type = "gguf";
            categories = [
              "analyst"
            ];
            priority = 5;
            settings = {
              opencode = {
                name = "Qwen3 4B Thinking Q64K";
                reasoning = true;
                tool_call = true;
                limit = {
                  context = 65536;
                  output = 8192;
                };
              };
              llama-cpp = {
                ctx-size = 65536;
                flash-attn = false;
                parallel = 1;

                temp = 0.6;
                top-p = 0.95;
                top-k = 20;
                repeat-penalty = 1.5;

                mlock = true;
                mmap = true;
              };
            };
            files = [
              (hfFile {
                repo = "unsloth/Qwen3-4B-Thinking-2507-GGUF";
                name = "Qwen3-4B-Thinking-2507-Q8_0.gguf";
                sha256 = "sha256-sVx79vRPrnVzWV/9WuLO68uybfkE/m2YuMmi+e6JZ7I=";
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
                name = "Qwen3 Coder 30B Instruct Q32K";
                reasoning = false;
                tool_call = true;
                limit = {
                  context = 32768;
                  output = 8192;
                };
              };
              llama-cpp = {
                ctx-size = 32768;
                flash-attn = false;
                parallel = 1;

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
                name = "Qwen2.5 Coder 7B Instruct Q32K";
                reasoning = false;
                tool_call = true;
                limit = {
                  context = 32768;
                  output = 8192;
                };
              };
              llama-cpp = {
                ctx-size = 32768;
                flash-attn = false;
                parallel = 1;

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
                repo = "Qwen/Qwen2.5-Coder-7B-Instruct-GGUF";
                name = "qwen2.5-coder-7b-instruct-q4_k_m.gguf";
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
                name = "Qwen3 VL 4B Instruct Q64K";
                reasoning = false;
                tool_call = true;
                limit = {
                  context = 65536;
                  output = 8192;
                };
              };
              llama-cpp = {
                ctx-size = 65536;
                flash-attn = false;
                parallel = 1;

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
