{
  config.substrate.modules.ai.llm.wintersteel = {
    tags = [
      "host:wintersteel"
      "service:ai:llm:models"
    ];

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
              sha256 = "sha256-Kl81ZfOc+IUQPaWRGCwSZtpkdFc3tCtFL9PmdTafEhE=";
            }
            {
              type = "huggingface";
              repo = "unsloth/Qwen3.8-27B-GGUF";
              name = "mmproj-F16.gguf";
              sha256 = "sha256-y7hBqe4GNrLsFy9buN8uqN/rAekP58YSZYHWYqC05D4=";
            }
          ];
        };
      };
    };
  };
}
