{
  config.substrate.modules.ai.llm.wintersteel = {
    tags = [ "host:wintersteel" ];

    homeManager = {
      config.hdwlinux.ai.llm.models = {
        "Qwen3.8-27B-UD-Q4_K_XL" = {
          type = "gguf";
          categories = [
            "coding"
            "fast"
            "reasoning"
          ];
          priority = 10;
          settings.llama-cpp = {
            ctx-size = 262144;
            flash-attn = true;
            mlock = true;
            mmap = true;
            n-gpu-layers = 999;
            parallel = 1;
          };
          files = [
            {
              type = "huggingface";
              repo = "unsloth/Qwen3.8-27B-GGUF";
              name = "Qwen3.8-27B-UD-Q4_K_XL.gguf";
              sha256 = "sha256-PyJweQA63SURQ35bHpSBLjYzhSJb9qm0ewBUpyvIsB4=";
            }
            {
              type = "huggingface";
              repo = "unsloth/Qwen3.8-27B-GGUF";
              name = "mmproj-F16.gguf";
              sha256 = "sha256-y7hBqe4GNrLsFy9buN8uqN/rAekP58YSZYHWYqC05D4=";
            }
          ];
        };

        "Qwen3.8-Flash-Next-UD-Q4_K_XL" = {
          type = "gguf";
          categories = [
            "coding"
            "long-context"
            "reasoning"
          ];
          priority = 20;
          settings.llama-cpp = {
            ctx-size = 262144;
            flash-attn = true;
            mlock = true;
            mmap = true;
            n-gpu-layers = 999;
            parallel = 1;
          };
          files = [
            {
              type = "huggingface";
              repo = "unsloth/Qwen3.8-Flash-Next-GGUF";
              subdir = "UD-Q4_K_XL";
              name = "Qwen3.8-Flash-Next-UD-Q4_K_XL-00001-of-00004.gguf";
              sha256 = "sha256-REgYYhazr0zFWLvOLDIT8BYI+Piy5SZ6l2eXHdPsgII=";
            }
            {
              type = "huggingface";
              repo = "unsloth/Qwen3.8-Flash-Next-GGUF";
              subdir = "UD-Q4_K_XL";
              name = "Qwen3.8-Flash-Next-UD-Q4_K_XL-00002-of-00004.gguf";
              sha256 = "sha256-PzQvHBWARz8e6U3dWyggbowHpw+ho2b1nR1skikZpsk=";
            }
            {
              type = "huggingface";
              repo = "unsloth/Qwen3.8-Flash-Next-GGUF";
              subdir = "UD-Q4_K_XL";
              name = "Qwen3.8-Flash-Next-UD-Q4_K_XL-00003-of-00004.gguf";
              sha256 = "sha256-VnWPQCacrVzZsNPW+64PQPbVvm3knkqzktvoMVfZy9M=";
            }
            {
              type = "huggingface";
              repo = "unsloth/Qwen3.8-Flash-Next-GGUF";
              subdir = "UD-Q4_K_XL";
              name = "Qwen3.8-Flash-Next-UD-Q4_K_XL-00004-of-00004.gguf";
              sha256 = "sha256-dTvaSLmLpPFjYTSpCpZ94bLTkIojbAJuRkd3NC5TUQo=";
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
