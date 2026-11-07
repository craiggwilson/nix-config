{
  config.substrate.modules.programs.opencode.agentgateway-discovery = {
    tags = [ "profile:ai" ];

    homeManager =
      { pkgs, ... }:
      let
        plugin = pkgs.runCommand "opencode-agentgateway-discovery" { } ''
          mkdir -p "$out"
          cp ${./agentgateway-discovery/server.js} "$out/server.js"
          cp ${./agentgateway-discovery/auth.js} "$out/auth.js"
          cp ${./agentgateway-discovery/model.js} "$out/model.js"
          cp ${./agentgateway-discovery/package.json} "$out/package.json"
        '';
      in
      {
        programs.opencode.settings.plugins = [
          {
            package = "${plugin}";
            options = {
              authIntegration = "agentgateway";
              # Keep matching rules in plugin options so discovery can run during plugin startup.
              providerGroups = [
                {
                  id = "agentgateway-copilot";
                  name = "AgentGateway - Copilot";
                  ownedBy = "copilot";
                  modelIdPrefix = "copilot/";
                  clientFormat = "responses";
                }
                {
                  id = "agentgateway-opencode-go";
                  name = "AgentGateway - OpenCode Go (Completions)";
                  ownedBy = "opencode-go/openai";
                  modelIdPrefix = "opencode-go/openai/";
                  clientFormat = "completions";
                }
                {
                  id = "agentgateway-opencode-go-responses";
                  name = "AgentGateway - OpenCode Go (Responses)";
                  ownedBy = "opencode-go/openai-responses";
                  modelIdPrefix = "opencode-go/openai-responses/";
                  # Completions -> Responses conversion does not exist in agentgateway.
                  clientFormat = "responses";
                }
                {
                  name = "AgentGateway - OpenCode Go (Anthropic)";
                  ownedBy = "opencode-go/anthropic";
                  modelIdPrefix = "opencode-go/anthropic/";
                  # agentgateway converts Completions -> Anthropic Messages upstream.
                }
                {
                  name = "AgentGateway - OpenCode Go (Google)";
                  ownedBy = "opencode-go/google";
                  modelIdPrefix = "opencode-go/google/";
                  # agentgateway converts Completions -> Gemini generateContent upstream.
                }
                # Tier aliases are resolved inside agentgateway (llm.virtualModels);
                # the plugin just needs the group named sensibly. Model IDs are the
                # bare tier names, so no prefix involved.
                {
                  name = "AgentGateway - Tiers";
                  ownedBy = "virtual";
                  clientFormat = "completions";
                }
              ];
            };
          }
        ];
      };
  };
}
