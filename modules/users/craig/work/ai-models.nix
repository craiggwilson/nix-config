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
            model = "claude-sonnet-4-6";
          };
          analyst = {
            provider = "augment";
            model = "claude-opus-4-8";
          };
          writer = {
            provider = "augment";
            model = "claude-sonnet-4-6";
          };
          code-reviewer = {
            provider = "augment";
            model = "code-review-gpt5-2-responses-high-200k-v1-c4-p2-agent";
          };
        };
      };
  };
}
