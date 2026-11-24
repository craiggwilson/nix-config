{
  config.substrate.modules.ai.llm.wintersteel = {
    tags = [
      "host:wintersteel"
      "service:ai:llm:models"
    ];

    homeManager = {
      config.hdwlinux.ai.llm.models = {
        "Inkling-2-Mini-UD-Q4_K_XL" = {
          type = "gguf";
          categories = [
            "coding"
            "fast"
            "reasoning"
          ];
          priority = 10;
          settings.llama-cpp = {
            # Looping means 48 KV caches for the 262144-token context; q8_0 halves the per-slot cost.
            cache-type-k = "q8_0";
            cache-type-v = "q8_0";
            fit = "off";
            flash-attn = true;
            kv-unified-per-slot = 262144;
            load-mode = "none";
            mmproj-offload = true;
            n-gpu-layers = "all";
            # The DSpark drafter (third file) is small; keep it fully on the GPU.
            n-gpu-layers-draft = 99;
            parallel = 3;
            # Depth 2 is the fastest for this model; the third draft token is rarely accepted.
            spec-draft-n-max = 2;
            spec-type = "draft-dspark";
            # TML's recommended sampling; greedy underuses the DSpark drafter.
            min-p = 0.0;
            temp = 1.0;
            top-k = 0;
            top-p = 1.0;
          };
          files = [
            {
              type = "huggingface";
              repo = "unsloth/Inkling-2-Mini-GGUF";
              name = "Inkling-2-Mini-UD-Q4_K_XL.gguf";
              sha256 = "e64276656f072e9b2197a61723667cbdb71da66a716ffd966e572c21088f3cd3";
            }
            {
              type = "huggingface";
              repo = "unsloth/Inkling-2-Mini-GGUF";
              name = "mmproj-F16.gguf";
              sha256 = "3bff75ffeb2d6e0371ba7bd42e30d26a7d98aea681fa44b03b5a20891cfa2c5f";
            }
            {
              type = "huggingface";
              repo = "unsloth/Inkling-2-Mini-GGUF";
              name = "dspark-Inkling-2-Mini-Q8_0.gguf";
              sha256 = "3da00cf7c31bbe5662b3c0d373ecf782d74d32ef43990acc158ce60c2add72e0";
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
