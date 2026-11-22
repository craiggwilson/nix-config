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
            # q8_0 KV halves the per-slot cost of the 262144-token context (~8 GiB vs ~16 GiB).
            cache-type-k = "q8_0";
            cache-type-v = "q8_0";
            fit = "off";
            flash-attn = true;
            kv-unified-per-slot = 262144;
            load-mode = "none";
            mmproj-offload = true;
            n-gpu-layers = "all";
            parallel = 3;
            # The GGUF embeds Qwen's MTP head (blk.64.nextn.*); it self-drafts with no extra model.
            spec-draft-n-max = 3;
            spec-type = "draft-mtp";
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

        "Qwen3-Embedding-8B-Q8_0" = {
          type = "gguf";
          categories = [ "embedding" ];
          settings.llama-cpp = {
            batch-size = 8192;
            embedding = true;
            fit = "off";
            flash-attn = true;
            kv-unified-per-slot = 8192;
            load-mode = "none";
            n-gpu-layers = "all";
            parallel = 2;
            pooling = "last";
            ubatch-size = 8192;
          };
          files = [
            {
              type = "huggingface";
              repo = "Qwen/Qwen3-Embedding-8B-GGUF";
              name = "Qwen3-Embedding-8B-Q8_0.gguf";
              sha256 = "d20ddc71e8a5c4344f2343481e242233a997dc5eaff442427a945836c97b4deb";
            }
          ];
        };

        # Qwen publishes no reranker GGUF and many community conversions drop
        # cls.output.weight; this conversion is reported to score correctly.
        "Qwen3-Reranker-4B-Q8_0" = {
          type = "gguf";
          categories = [ "reranker" ];
          settings.llama-cpp = {
            batch-size = 8192;
            embedding = true;
            fit = "off";
            flash-attn = true;
            kv-unified-per-slot = 8192;
            load-mode = "none";
            n-gpu-layers = "all";
            parallel = 2;
            pooling = "rank";
            reranking = true;
            ubatch-size = 8192;
          };
          files = [
            {
              type = "huggingface";
              repo = "Voodisss/Qwen3-Reranker-4B-GGUF-llama_cpp";
              name = "Qwen3-Reranker-4B.Q8_0.gguf";
              sha256 = "102ac400d68f02877c2fdfecf0732872652298448352b6faf28ec7f8dca8c913";
            }
          ];
        };
      };
    };
  };
}
