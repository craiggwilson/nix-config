{
  config.substrate.modules.ai.llm.wintersteel-flash = {
    tags = [
      "host:wintersteel"
      "service:ai:llm:flash-next"
    ];

    homeManager = {
      config.hdwlinux.ai.llm.models = {
        "Qwen3.8-Flash-Next-UD-Q4_K_XL" = {
          type = "gguf";
          categories = [
            "coding"
            "long-context"
            "reasoning"
          ];
          priority = 20;
          settings.llama-cpp = {
            fit = "off";
            flash-attn = true;
            kv-unified-per-slot = 262144;
            load-on-startup = false;
            load-mode = "none";
            mmproj-offload = true;
            n-gpu-layers = "all";
            parallel = 2;
          };
          files = [
            {
              type = "huggingface";
              repo = "unsloth/Qwen3.8-Flash-Next-GGUF";
              subdir = "UD-Q4_K_XL";
              name = "Qwen3.8-Flash-Next-UD-Q4_K_XL-00001-of-00004.gguf";
              sha256 = "sha256-rMRAQPdNDlX7icOWcFbM5dvaG8xS6QnDum/HK16cCFg=";
            }
            {
              type = "huggingface";
              repo = "unsloth/Qwen3.8-Flash-Next-GGUF";
              subdir = "UD-Q4_K_XL";
              name = "Qwen3.8-Flash-Next-UD-Q4_K_XL-00002-of-00004.gguf";
              sha256 = "sha256-RXkq6GkHLYIpOExRx8c92VnhkVBSUrQd1xhS2XRvXOQ=";
            }
            {
              type = "huggingface";
              repo = "unsloth/Qwen3.8-Flash-Next-GGUF";
              subdir = "UD-Q4_K_XL";
              name = "Qwen3.8-Flash-Next-UD-Q4_K_XL-00003-of-00004.gguf";
              sha256 = "sha256-jHbnnURLFqZj2cjbVOWF7TsdoT7r0mGcN7DDVdqAPII=";
            }
            {
              type = "huggingface";
              repo = "unsloth/Qwen3.8-Flash-Next-GGUF";
              subdir = "UD-Q4_K_XL";
              name = "Qwen3.8-Flash-Next-UD-Q4_K_XL-00004-of-00004.gguf";
              sha256 = "sha256-Xei12/iUCazDlGjeyv1KSpWxPCnYihSwNWEHiXgp7DY=";
            }
            {
              type = "huggingface";
              repo = "unsloth/Qwen3.8-Flash-Next-GGUF";
              name = "mmproj-F16.gguf";
              sha256 = "sha256-H3t/C5hM8GXGBDYMKcgJg2LtYbKQ2w/xLG82C7GoqYA=";
            }
          ];
        };
      };
    };
  };
}
