{
  config.substrate.modules.users.craig.personal."ai-models" = {
    tags = [
      "users:craig:personal"
      "ai:clients"
    ];

    homeManager =
      { lib, ... }:
      {
        hdwlinux.ai.clients.models.aliases = lib.mkDefault {
          fast = {
            provider = "opencode-go";
            model = "deepseek-v4-flash";
          };
          balanced = {
            provider = "opencode-go";
            model = "deepseek-v4-pro";
          };
          coder = {
            provider = "opencode-go";
            model = "kimi-k2.7-code";
          };
          analyst = {
            provider = "opencode-go";
            model = "qwen3.7-max";
          };
          writer = {
            provider = "opencode-go";
            model = "qwen3.7-plus";
          };
          code-reviewer = {
            provider = "opencode-go";
            model = "kimi-k2.7-code";
          };
          vision = {
            provider = "opencode-go";
            model = "qwen3.7-max";
          };
        };
      };
  };
}
