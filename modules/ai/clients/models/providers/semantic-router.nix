{
  config.substrate.modules.ai.clients.models.providers."semantic-router" = {
    tags = [
      "ai:clients"
      "ai:llm"
    ];

    homeManager =
      { lib, ... }:
      {
        hdwlinux.ai.clients.models.providers."semantic-router" = {
          displayName = "Semantic Router";
          models = {
            router = {
              displayName = "Semantic Router";
              limits = {
                context = 262144;
                output = 8192;
              };
            };
          };
        };

        hdwlinux.ai.clients.models.aliases = lib.mkForce {
          fast = {
            provider = "semantic-router";
            model = "router";
          };
          balanced = {
            provider = "semantic-router";
            model = "router";
          };
          coder = {
            provider = "semantic-router";
            model = "router";
          };
          code-reviewer = {
            provider = "semantic-router";
            model = "router";
          };
          analyst = {
            provider = "semantic-router";
            model = "router";
          };
          writer = {
            provider = "semantic-router";
            model = "router";
          };
          vision = {
            provider = "semantic-router";
            model = "router";
          };
        };
      };
  };
}
