{
  config.substrate.modules.ai.agent.models.providers.augment = {
    tags = [
      "users:craig:work"
      "ai:agent"
    ];

    homeManager =
      { lib, ... }:
      {
        hdwlinux.ai.agent.models.providers.augment = {
          displayName = "Augment Code";
          models = {
            "claude-haiku-4-5" = {
              displayName = "Claude Haiku 4.5";
              limits = {
                context = 200000;
                output = 8000;
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
            "claude-sonnet-4" = {
              displayName = "Claude Sonnet 4";
              limits = {
                context = 200000;
                output = 16000;
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
            "gpt-5" = {
              displayName = "GPT 5";
              limits = {
                context = 400000;
                output = 32000;
              };
            };
            "gpt-5-1" = {
              displayName = "GPT 5.1";
              limits = {
                context = 400000;
                output = 32000;
              };
            };
            "gpt-5-2" = {
              displayName = "GPT 5.2";
              limits = {
                context = 400000;
                output = 32000;
              };
            };
          };
        };

        hdwlinux.ai.agent.models.aliases = lib.mkDefault {
          fast = {
            provider = "augment";
            model = "claude-haiku-4-5";
          };
          balanced = {
            provider = "augment";
            model = "claude-sonnet-4-5";
          };
          coder = {
            provider = "augment";
            model = "claude-opus-4-5";
          };
          analyst = {
            provider = "augment";
            model = "claude-opus-4-5";
          };
          writer = {
            provider = "augment";
            model = "claude-sonnet-4-5";
          };
        };
      };
  };
}
