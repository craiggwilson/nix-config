{
  config.substrate.modules.ai.clients.models.providers.augment = {
    tags = [
      "users:craig:work"
      "ai:clients"
    ];

    homeManager =
      { lib, ... }:
      {
        hdwlinux.ai.clients.models.providers.augment = {
          displayName = "Augment Code";
          models = {
            # Anthropic Claude models
            "claude-haiku-4-5" = {
              displayName = "Claude Haiku 4.5";
              limits = {
                context = 200000;
                output = 8000;
              };
            };
            "claude-sonnet-4-6" = {
              displayName = "Claude Sonnet 4.6";
              limits = {
                context = 200000;
                output = 16000;
              };
            };
            "claude-opus-4-8" = {
              displayName = "Claude Opus 4.8";
              limits = {
                context = 200000;
                output = 32000;
              };
            };
            # Google Gemini models
            "gemini-3-1-pro-preview" = {
              displayName = "Gemini 3.1 Pro";
              limits = {
                context = 200000;
                output = 32000;
              };
            };
            # OpenAI GPT models
            "gpt-5-4" = {
              displayName = "GPT 5.4";
              limits = {
                context = 400000;
                output = 32000;
              };
            };
          };
        };

        hdwlinux.ai.clients.models.aliases = lib.mkDefault {
          fast = {
            provider = "augment";
            model = "claude-haiku-4-5";
          };
          balanced = {
            provider = "augment";
            model = "claude-sonnet-4-6";
          };
          coder = {
            provider = "augment";
            model = "claude-haiku-4-5";
          };
          analyst = {
            provider = "augment";
            model = "claude-opus-4-8";
          };
          writer = {
            provider = "augment";
            model = "claude-sonnet-4-6";
          };
        };
      };
  };
}
