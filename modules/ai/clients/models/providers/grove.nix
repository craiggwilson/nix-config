{
  config.substrate.modules.ai.clients.models.providers.grove = {
    tags = [
      "users:craig:work"
      "ai:clients"
    ];

    homeManager =
      { lib, ... }:
      let
        # Catalog from grove-gateway-opencode-plugin v1.3.0. Keys are the
        # gateway's API model IDs, which is what OpenCode addresses models by.
        groveModels = import ./_grove_models.nix;
        mkModels = lib.mapAttrs (
          _: model: {
            displayName = model.name;
            limits = model.limit;
          }
        );

        # v1.3.0's gateway is what the current key works with. Upstream has
        # since moved to ai-gateway.corp.mongodb.com with an `x-api-key` header
        # and a different key — update here when migrating.
        baseURL = "https://grove-gateway-prod.azure-api.net/grove-foundry-prod";

        # The gateway exposes three API flavors behind the same key.
        providerSpecs = {
          anthropic = {
            name = "Anthropic";
            package = "aisdk:@ai-sdk/anthropic";
            path = "/anthropic/v1";
          };
          misc = {
            name = "Misc";
            package = "aisdk:@ai-sdk/openai-compatible";
            path = "/openai/v1";
          };
          openai = {
            name = "OpenAI";
            package = "aisdk:@ai-sdk/openai";
            path = "/openai/v1";
          };
        };
      in
      {
        hdwlinux.ai.clients.models.providers = lib.mapAttrs' (
          type: spec:
          lib.nameValuePair "grove-${type}" {
            displayName = "Grove ${spec.name}";
            models = mkModels groveModels.${type};
            secret = "GROVE_API_KEY";

            # The gateway authenticates with an `api-key` header, not the SDK's
            # native Bearer auth, so OpenCode must send the credential itself.
            settings.opencode = {
              env = [ "GROVE_API_KEY" ];
              headers."api-key" = "{env:GROVE_API_KEY}";
              inherit (spec) package;
              settings.baseURL = "${baseURL}${spec.path}";
            };
          }
        ) providerSpecs;

        # Shared by all three providers; the key already lives in 1Password.
        secretspec.entries.GROVE_API_KEY = {
          description = "Grove AI Gateway API key for the grove-* model providers";
          ref = {
            field = "primary_api_key";
            item = "Grove";
            vault = "Work";
          };
        };
      };
  };
}
