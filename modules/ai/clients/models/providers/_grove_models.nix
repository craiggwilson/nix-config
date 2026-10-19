# Generated from 10gen/grove-gateway-opencode-plugin v1.3.0 (models.jsonc +
# models-dev snapshot). Keys are the gateway's API model IDs (groveModelId);
# regenerate when the gateway catalog changes.
{
  "openai" = {
    "gpt-5.5" = {
      "name" = "GPT 5.5";
      "limit" = {
        "context" = 1050000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5.6-sol" = {
      "name" = "GPT 5.6 Sol";
      "limit" = {
        "context" = 1050000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5.6-terra" = {
      "name" = "GPT 5.6 Terra";
      "limit" = {
        "context" = 1050000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5.6-luna" = {
      "name" = "GPT 5.6 Luna";
      "limit" = {
        "context" = 1050000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5.4" = {
      "name" = "GPT 5.4";
      "limit" = {
        "context" = 1050000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5.4-mini" = {
      "name" = "GPT 5.4 Mini";
      "limit" = {
        "context" = 400000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5.4-nano" = {
      "name" = "GPT 5.4 Nano";
      "limit" = {
        "context" = 400000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5.2" = {
      "name" = "GPT 5.2";
      "limit" = {
        "context" = 400000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5.3-codex" = {
      "name" = "GPT 5.3 Codex";
      "limit" = {
        "context" = 400000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5.2-codex" = {
      "name" = "GPT 5.2 Codex";
      "limit" = {
        "context" = 400000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5.1" = {
      "name" = "GPT 5.1";
      "limit" = {
        "context" = 272000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5.1-codex" = {
      "name" = "GPT 5.1 Codex";
      "limit" = {
        "context" = 400000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5.1-codex-mini" = {
      "name" = "GPT 5.1 Codex Mini";
      "limit" = {
        "context" = 400000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5.1-codex-max" = {
      "name" = "GPT 5.1 Codex Max";
      "limit" = {
        "context" = 400000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5" = {
      "name" = "GPT 5";
      "limit" = {
        "context" = 272000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5-mini" = {
      "name" = "GPT 5 Mini";
      "limit" = {
        "context" = 272000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5-nano" = {
      "name" = "GPT 5 Nano";
      "limit" = {
        "context" = 272000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-5-codex" = {
      "name" = "GPT 5 Codex";
      "limit" = {
        "context" = 400000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-4.1" = {
      "name" = "GPT 4.1";
      "limit" = {
        "context" = 1047576;
        "output" = 32768;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-4.1-mini" = {
      "name" = "GPT 4.1 Mini";
      "limit" = {
        "context" = 1047576;
        "output" = 32768;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-4.1-nano" = {
      "name" = "GPT 4.1 Nano";
      "limit" = {
        "context" = 1047576;
        "output" = 32768;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-4o" = {
      "name" = "GPT 4o";
      "limit" = {
        "context" = 128000;
        "output" = 16384;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "gpt-4o-mini" = {
      "name" = "GPT 4o Mini";
      "limit" = {
        "context" = 128000;
        "output" = 16384;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "o1" = {
      "name" = "o1";
      "limit" = {
        "context" = 200000;
        "output" = 100000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
  };
  "anthropic" = {
    "claude-fable-5" = {
      "name" = "Claude Fable 5";
      "limit" = {
        "context" = 1000000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "claude-sonnet-5" = {
      "name" = "Claude Sonnet 5";
      "limit" = {
        "context" = 1000000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "claude-opus-4-8" = {
      "name" = "Claude Opus 4.8";
      "limit" = {
        "context" = 200000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "claude-opus-4-7" = {
      "name" = "Claude Opus 4.7";
      "limit" = {
        "context" = 1000000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "claude-opus-4-6" = {
      "name" = "Claude Opus 4.6";
      "limit" = {
        "context" = 200000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "claude-sonnet-4-6" = {
      "name" = "Claude Sonnet 4.6";
      "limit" = {
        "context" = 1000000;
        "output" = 64000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "claude-opus-4-5" = {
      "name" = "Claude Opus 4.5";
      "limit" = {
        "context" = 200000;
        "output" = 64000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "claude-sonnet-4-5" = {
      "name" = "Claude Sonnet 4.5";
      "limit" = {
        "context" = 200000;
        "output" = 64000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "claude-haiku-4-5" = {
      "name" = "Claude Haiku 4.5";
      "limit" = {
        "context" = 200000;
        "output" = 64000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "claude-opus-4-1" = {
      "name" = "Claude Opus 4.1";
      "limit" = {
        "context" = 200000;
        "output" = 32000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
  };
  "misc" = {
    "Llama-4-Maverick-17B-128E-Instruct-FP8" = {
      "name" = "Llama 4 Maverick";
      "limit" = {
        "context" = 128000;
        "output" = 8192;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "Llama-4-Scout-17B-16E-Instruct" = {
      "name" = "Llama 4 Scout";
      "limit" = {
        "context" = 128000;
        "output" = 8192;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "Mistral-Large-3" = {
      "name" = "Mistral Large 3";
      "limit" = {
        "context" = 128000;
        "output" = 32768;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "mistral-medium-2505" = {
      "name" = "Mistral Medium";
      "limit" = {
        "context" = 128000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "mistral-small-2503" = {
      "name" = "Mistral Small";
      "limit" = {
        "context" = 128000;
        "output" = 32768;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "cohere-command-a" = {
      "name" = "Cohere Command A";
      "limit" = {
        "context" = 256000;
        "output" = 8000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "Phi-4" = {
      "name" = "Phi 4";
      "limit" = {
        "context" = 128000;
        "output" = 4096;
      };
    };
    "Phi-4-reasoning" = {
      "name" = "Phi 4 Reasoning";
      "limit" = {
        "context" = 32000;
        "output" = 4096;
      };
    };
    "Phi-4-mini-instruct" = {
      "name" = "Phi 4 Mini";
      "limit" = {
        "context" = 128000;
        "output" = 4096;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "Phi-4-mini-reasoning" = {
      "name" = "Phi 4 Mini Reasoning";
      "limit" = {
        "context" = 128000;
        "output" = 4096;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "DeepSeek-V4-Flash" = {
      "name" = "DeepSeek V4 Flash";
      "limit" = {
        "context" = 1000000;
        "output" = 384000;
      };
    };
    "DeepSeek-V3.2" = {
      "name" = "DeepSeek V3.2";
      "limit" = {
        "context" = 128000;
        "output" = 128000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "DeepSeek-V3.2-Speciale" = {
      "name" = "DeepSeek V3.2 Speciale";
      "limit" = {
        "context" = 128000;
        "output" = 128000;
      };
    };
    "grok-4-20-reasoning" = {
      "name" = "Grok 4.2 Reasoning";
      "limit" = {
        "context" = 262000;
        "output" = 8192;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "grok-4-20-non-reasoning" = {
      "name" = "Grok 4.2 Non-Reasoning";
      "limit" = {
        "context" = 262000;
        "output" = 8192;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "grok-4.3" = {
      "name" = "Grok 4.3";
      "limit" = {
        "context" = 1000000;
        "output" = 30000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "grok-4-1-fast-reasoning" = {
      "name" = "Grok 4.1 Fast Reasoning";
      "limit" = {
        "context" = 128000;
        "output" = 8192;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "grok-4-1-fast-non-reasoning" = {
      "name" = "Grok 4.1 Fast";
      "limit" = {
        "context" = 128000;
        "output" = 8192;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "grok-code-fast-1" = {
      "name" = "Grok Code Fast 1";
      "limit" = {
        "context" = 256000;
        "output" = 256000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "Kimi-K2.6" = {
      "name" = "Kimi K2.6";
      "limit" = {
        "context" = 262144;
        "output" = 262144;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "Kimi-K2.5" = {
      "name" = "Kimi K2.5";
      "limit" = {
        "context" = 262144;
        "output" = 262144;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "Kimi-K2-Thinking" = {
      "name" = "Kimi K2 Thinking";
      "limit" = {
        "context" = 262144;
        "output" = 262144;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "FW-MiniMax-M2.5" = {
      "name" = "FW MiniMax M2.5";
      "limit" = {
        "context" = 204800;
        "output" = 131072;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "FW-DeepSeek-V4-Pro" = {
      "name" = "FW DeepSeek V4 Pro";
      "limit" = {
        "context" = 1000000;
        "output" = 384000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "FW-GLM-5.1" = {
      "name" = "FW GLM 5.1";
      "limit" = {
        "context" = 202800;
        "output" = 131072;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "FW-GLM-5.2" = {
      "name" = "FW GLM 5.2";
      "limit" = {
        "context" = 1048575;
        "output" = 131072;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "FW-Kimi-K2.6" = {
      "name" = "FW Kimi K2.6";
      "limit" = {
        "context" = 262000;
        "output" = 262000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
    "FW-Kimi-K2.7-Code" = {
      "name" = "FW Kimi K2.7 Code";
      "limit" = {
        "context" = 262000;
        "output" = 262000;
      };
      "capabilities" = {
        "tools" = true;
      };
    };
  };
}
