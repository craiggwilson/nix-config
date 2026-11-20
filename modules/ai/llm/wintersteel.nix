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

        # QAT build: Unsloth reports higher-precision quants of it lose accuracy.
        "gemma-4-26B-A4B-it-qat-UD-Q4_K_XL" = {
          type = "gguf";
          categories = [
            "fast"
            "writer"
          ];
          priority = 5;
          settings.llama-cpp = {
            fit = "off";
            flash-attn = true;
            kv-unified-per-slot = 262144;
            load-mode = "none";
            mmproj-offload = true;
            n-gpu-layers = "all";
            parallel = 2;
            # The QAT GGUF strips the MTP head, so gemma drafts with an EAGLE-3 speculator instead.
            spec-draft-n-max = 4;
            spec-draft-p-min = 0.5;
            spec-type = "draft-eagle3";
            temp = 1.0;
            top-k = 64;
            top-p = 0.95;
          };
          files = [
            {
              type = "huggingface";
              repo = "unsloth/gemma-4-26B-A4B-it-qat-GGUF";
              name = "gemma-4-26B-A4B-it-qat-UD-Q4_K_XL.gguf";
              sha256 = "a7c5bc715f5ff8e99a3e8901ce7d2b42b402c669bf24f7c5250747633d0f5891";
            }
            {
              type = "huggingface";
              repo = "unsloth/gemma-4-26B-A4B-it-qat-GGUF";
              name = "mmproj-BF16.gguf";
              sha256 = "7b06953ccdbe8cf363f47841a7afaacd2b1c2ff9a8d6b426fdec7521a6878744";
            }
            # EAGLE-3 draft head trained for this exact target model (RedHatAI checkpoint, community GGUF).
            {
              type = "huggingface";
              repo = "williamliao/gemma-4-26B-A4B-it-speculator.eagle3-F16-GGUF";
              name = "gemma-4-26B-A4B-it-speculator.eagle3-Q8_0.gguf";
              sha256 = "7e4eb3e400608378b89a66a3af5707539f54ff64571697af1a8b3779bdd52a24";
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
