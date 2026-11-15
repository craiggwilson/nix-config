{
  config.substrate.modules.ai.clients.models.grove = {
    tags = [
      "user:craig"
      "profile:work"
      "profile:ai"
    ];

    homeManager =
      _:
      let
        # v1.3.0's gateway is what the current key works with. Upstream has
        # since moved to ai-gateway.corp.mongodb.com with an `x-api-key` header
        # and a different key — update here when migrating.
        baseURL = "https://grove-gateway-prod.azure-api.net/grove-foundry-prod";

        # The gateway exposes three API flavors behind the same key, which it
        # authenticates with an `api-key` header rather than Bearer auth.
        flavor = name: path: format: package: {
          formats = [ format ];
          auth = {
            header = "api-key";
            prefix = "";
            secret = "GROVE_API_KEY";
          };
          displayName = "Grove ${name}";
          baseURL = "${baseURL}${path}";
          settings.opencode.package = package;
        };
      in
      {
        hdwlinux.ai.clients.models.providers = {
          grove-anthropic = flavor "Anthropic" "/anthropic/v1" "anthropic" "aisdk:@ai-sdk/anthropic";
          grove-misc = flavor "Misc" "/openai/v1" "completions" "aisdk:@ai-sdk/openai-compatible";
          grove-openai = flavor "OpenAI" "/openai/v1" "responses" "aisdk:@ai-sdk/openai";
        };
      };
  };
}
