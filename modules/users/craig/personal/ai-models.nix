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
          analysis = {
            provider = "opencode-go";
            model = "qwen3.7-max";
          };
          balanced = {
            provider = "opencode-go";
            model = "deepseek-v4-pro";
          };
          code-review = {
            provider = "opencode-go";
            model = "kimi-k2.7-code";
          };
          coding = {
            provider = "opencode-go";
            model = "kimi-k2.7-code";
          };
          fast = {
            provider = "opencode-go";
            model = "mimo-v2.5";
          };
          orchestration = {
            provider = "opencode-go";
            model = "deepseek-v4-pro";
          };
          research = {
            provider = "opencode-go";
            model = "qwen3.7-plus";
          };
          writing = {
            provider = "opencode-go";
            model = "qwen3.7-plus";
          };
        };
      };
  };
}
