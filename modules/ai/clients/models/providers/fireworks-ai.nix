{
  config.substrate.modules.ai.clients.models.providers.fireworks-ai = {
    tags = [
      "users:craig:work"
      "ai:clients"
    ];

    homeManager =
      { lib, ... }:
      {
        hdwlinux.ai.clients.models.providers.fireworks-ai = {
          displayName = "Fireworks AI";
          models = {
            "accounts/fireworks/models/deepseek-v4p1-flash" = {
              displayName = "DeepSeek V4.1 Flash";
              limits = {
                context = 1000000;
                output = 384000;
              };
            };
            "accounts/fireworks/models/ember-1" = {
              displayName = "Ember-1";
              limits = {
                context = 1048576;
                output = 131072;
              };
            };
            "accounts/fireworks/models/glm-5p3" = {
              displayName = "GLM 5.3";
              limits = {
                context = 1048573;
                output = 262144;
              };
            };
            "accounts/fireworks/models/glm-5p3-flash" = {
              displayName = "GLM 5.3 Flash";
              limits = {
                context = 1048573;
                output = 131072;
              };
            };
            "accounts/fireworks/models/gpt-oss-120b" = {
              displayName = "GPT-OSS 120B";
              limits = {
                context = 131072;
                output = 32768;
              };
            };
            "accounts/fireworks/models/inkling" = {
              displayName = "Inkling";
              limits = {
                context = 1048576;
                output = 1048576;
              };
            };
            "accounts/fireworks/models/kimi-k3" = {
              displayName = "Kimi K3";
              limits = {
                context = 1048576;
                output = 131072;
              };
            };
            "accounts/fireworks/models/minimax-m3" = {
              displayName = "MiniMax M3";
              limits = {
                context = 512000;
                output = 512000;
              };
            };
            "accounts/fireworks/models/nemotron-3-ultra-nvfp4" = {
              displayName = "Nemotron 3 Ultra";
              limits = {
                context = 262144;
                output = 128000;
              };
            };
            "accounts/fireworks/models/nemotron-lightning-3p5-30b-a3b" = {
              displayName = "Nemotron Lightning 3.5 30B";
              limits = {
                context = 262144;
                output = 262144;
              };
            };
            "accounts/fireworks/models/qwen3p7-plus" = {
              displayName = "Qwen3.7 Plus";
              limits = {
                context = 262144;
                output = 65536;
              };
            };
            "accounts/fireworks/models/qwen3p8-2p4t-a95b" = {
              displayName = "Qwen3.8 2.4T A95B";
              limits = {
                context = 262144;
                output = 131072;
              };
            };
            "accounts/fireworks/models/qwen3p8-max" = {
              displayName = "Qwen3.8 Max";
              limits = {
                context = 262144;
                output = 131072;
              };
            };
            # Routers track the latest model in each family; fast variants are priority-served.
            "accounts/fireworks/routers/deepseek-flash-latest" = {
              displayName = "DeepSeek Flash Latest";
              limits = {
                context = 1000000;
                output = 384000;
              };
            };
            "accounts/fireworks/routers/deepseek-pro-latest" = {
              displayName = "DeepSeek Pro Latest";
              limits = {
                context = 1000000;
                output = 384000;
              };
            };
            "accounts/fireworks/routers/glm-flash-latest" = {
              displayName = "GLM Flash Latest";
              limits = {
                context = 1048573;
                output = 131072;
              };
            };
            "accounts/fireworks/routers/glm-latest" = {
              displayName = "GLM Latest";
              limits = {
                context = 1048573;
                output = 262144;
              };
            };
            "accounts/fireworks/routers/kimi-latest" = {
              displayName = "Kimi Latest";
              limits = {
                context = 1048576;
                output = 131072;
              };
            };
            "accounts/fireworks/routers/minimax-latest" = {
              displayName = "MiniMax Latest";
              limits = {
                context = 512000;
                output = 512000;
              };
            };
            "accounts/fireworks/routers/qwen-max-latest" = {
              displayName = "Qwen Max Latest";
              limits = {
                context = 262144;
                output = 131072;
              };
            };
          };
        };
      };
  };
}
