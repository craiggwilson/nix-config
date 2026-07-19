{
  config.substrate.modules.ai.clients.models.providers."opencode-go" = {
    tags = [ "ai:clients" ];

    homeManager = {
      hdwlinux.ai.clients.models.providers."opencode-go" = {
        displayName = "OpenCode Go";
        models = {
          "deepseek-v4-flash" = {
            displayName = "DeepSeek V4 Flash";
            limits = {
              context = 200000;
              output = 16000;
            };
          };
          "deepseek-v4-pro" = {
            displayName = "DeepSeek V4 Pro";
            limits = {
              context = 200000;
              output = 16000;
            };
          };
          "glm-5.1" = {
            displayName = "GLM-5.1";
            limits = {
              context = 200000;
              output = 16000;
            };
          };
          "glm-5.2" = {
            displayName = "GLM-5.2";
            limits = {
              context = 200000;
              output = 32000;
            };
          };
          "grok-4.5" = {
            displayName = "Grok 4.5";
            limits = {
              context = 200000;
              output = 16000;
            };
          };
          "kimi-k2.6" = {
            displayName = "Kimi K2.6";
            limits = {
              context = 200000;
              output = 16000;
            };
          };
          "kimi-k2.7-code" = {
            displayName = "Kimi K2.7 Code";
            limits = {
              context = 200000;
              output = 16000;
            };
          };
          "kimi-k3" = {
            displayName = "Kimi K3";
            limits = {
              context = 200000;
              output = 32000;
            };
          };
          "mimo-v2.5" = {
            displayName = "MiMo-V2.5";
            limits = {
              context = 200000;
              output = 16000;
            };
          };
          "mimo-v2.5-pro" = {
            displayName = "MiMo-V2.5-Pro";
            limits = {
              context = 200000;
              output = 16000;
            };
          };
          "minimax-m2.7" = {
            displayName = "MiniMax M2.7";
            limits = {
              context = 200000;
              output = 16000;
            };
          };
          "minimax-m3" = {
            displayName = "MiniMax M3";
            limits = {
              context = 200000;
              output = 16000;
            };
          };
          "qwen3.6-plus" = {
            displayName = "Qwen3.6 Plus";
            limits = {
              context = 200000;
              output = 16000;
            };
          };
          "qwen3.7-max" = {
            displayName = "Qwen3.7 Max";
            limits = {
              context = 200000;
              output = 32000;
            };
          };
          "qwen3.7-plus" = {
            displayName = "Qwen3.7 Plus";
            limits = {
              context = 200000;
              output = 16000;
            };
          };
        };
      };
    };
  };
}
