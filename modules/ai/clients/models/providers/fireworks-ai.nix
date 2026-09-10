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
            "accounts/fireworks/models/deepseek-v4-flash-0731" = {
              displayName = "DeepSeek V4 Flash";
              limits = {
                context = 1040000;
                output = 384000;
              };
            };
            "accounts/fireworks/models/deepseek-v4-flash-vision-exp" = {
              displayName = "DeepSeek V4 Flash Vision Exp";
              limits = {
                context = 1040000;
                output = 384000;
              };
            };
            "accounts/fireworks/models/deepseek-v4-pro-0813" = {
              displayName = "DeepSeek V4 Pro";
              limits = {
                context = 1040000;
                output = 384000;
              };
            };
            "accounts/fireworks/models/deepseek-v4p1-flash" = {
              displayName = "DeepSeek V4.1 Flash";
              limits = {
                context = 1040000;
                output = 384000;
              };
            };
            "accounts/fireworks/models/glm-5p2" = {
              displayName = "GLM 5.2";
              limits = {
                context = 1040000;
                output = 131072;
              };
            };
            "accounts/fireworks/models/glm-5p3" = {
              displayName = "GLM 5.3";
              limits = {
                context = 1040000;
                output = 131072;
              };
            };
            "accounts/fireworks/models/glm-5p3-flash" = {
              displayName = "GLM 5.3 Flash";
              limits = {
                context = 1040000;
                output = 131072;
              };
            };
            "accounts/fireworks/models/gpt-oss-120b" = {
              displayName = "GPT-OSS 120B";
              limits = {
                context = 128000;
                output = 32768;
              };
            };
            "accounts/fireworks/models/inkling" = {
              displayName = "Inkling";
              limits = {
                context = 1040000;
                output = 131072;
              };
            };
            "accounts/fireworks/models/kimi-k2p6" = {
              displayName = "Kimi K2.6";
              limits = {
                context = 262144;
                output = 65536;
              };
            };
            "accounts/fireworks/models/kimi-k2p7-code" = {
              displayName = "Kimi K2.7 Code";
              limits = {
                context = 262144;
                output = 262144;
              };
            };
            "accounts/fireworks/models/kimi-k3" = {
              displayName = "Kimi K3";
              limits = {
                context = 1040000;
                output = 131072;
              };
            };
            "accounts/fireworks/models/minimax-m3" = {
              displayName = "MiniMax M3";
              limits = {
                context = 512000;
                output = 131072;
              };
            };
            "accounts/fireworks/models/mistral-large-3-fp8" = {
              displayName = "Mistral Large 3";
              limits = {
                context = 256000;
                output = 32768;
              };
            };
            "accounts/fireworks/models/muse-glimmer-30b" = {
              displayName = "Muse Glimmer 30B";
              limits = {
                context = 131000;
                output = 32768;
              };
            };
            "accounts/fireworks/models/nemotron-3-ultra-nvfp4" = {
              displayName = "Nemotron 3 Ultra";
              limits = {
                context = 262144;
                output = 32768;
              };
            };
            "accounts/fireworks/models/nemotron-lightning-3p5-30b-a3b" = {
              displayName = "Nemotron Lightning 3.5 30B";
              limits = {
                context = 262144;
                output = 32768;
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
                context = 1000000;
                output = 131072;
              };
            };
          };
        };
      };
  };
}
