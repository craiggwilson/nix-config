{
  config.substrate.modules.ai.agent.models.providers.anthropic = {
    tags = [
      "users:craig:work"
      "ai:agent"
    ];

    homeManager =
      { lib, ... }:
      {
        hdwlinux.ai.agent.models.providers.anthropic = {
          displayName = "Anthropic";
          models = {
            "claude-haiku-4-5" = {
              displayName = "Claude Haiku 4.5";
              limits = {
                context = 200000;
                output = 8000;
              };
            };
            "claude-sonnet-4-5" = {
              displayName = "Claude Sonnet 4.5";
              limits = {
                context = 200000;
                output = 16000;
              };
            };
            "claude-sonnet-4-6" = {
              displayName = "Claude Sonnet 4.6";
              limits = {
                context = 200000;
                output = 16000;
              };
            };
            "claude-opus-4-5" = {
              displayName = "Claude Opus 4.5";
              limits = {
                context = 200000;
                output = 32000;
              };
            };
            "claude-opus-4-6" = {
              displayName = "Claude Opus 4.6";
              limits = {
                context = 200000;
                output = 32000;
              };
            };
          };
        };

        # Lowest priority - augment or llama.cpp aliases take precedence
        hdwlinux.ai.agent.models.aliases = lib.mkOptionDefault {
          fast = {
            provider = "anthropic";
            model = "claude-haiku-4-5";
          };
          balanced = {
            provider = "anthropic";
            model = "claude-sonnet-4-6";
          };
          coder = {
            provider = "anthropic";
            model = "claude-sonnet-4-6";
          };
          analyst = {
            provider = "anthropic";
            model = "claude-opus-4-5";
          };
          writer = {
            provider = "anthropic";
            model = "claude-sonnet-4-6";
          };
        };
      };
  };
}
