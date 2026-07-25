{
  config.substrate.modules.users.craig.work."ai-models" = {
    tags = [
      "users:craig:work"
      "ai:clients"
    ];

    homeManager =
      { lib, ... }:
      {
        hdwlinux.ai.clients.models.aliases = lib.mkDefault {
          analysis = {
            provider = "grove-misc";
            model = "fw-glm-5.2";
          };
          balanced = {
            provider = "grove-anthropic";
            model = "claude-sonnet-5";
          };
          code-review = {
            provider = "grove-misc";
            model = "fw-glm-5.2";
          };
          coding = {
            provider = "grove-misc";
            model = "fw-deepseek-v4-pro";
          };
          fast = {
            provider = "grove-anthropic";
            model = "claude-haiku-4-5";
          };
          orchestration = {
            provider = "grove-anthropic";
            model = "claude-opus-4-8";
          };
          research = {
            provider = "grove-openai";
            model = "gpt-5.6-luna";
          };
          writing = {
            provider = "grove-openai";
            model = "gpt-5.6-luna";
          };
        };
      };
  };
}
