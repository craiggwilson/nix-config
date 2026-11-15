# OpenCode binds a provider to one SDK package, so models that should use
# different API formats need separate providers. The discovery plugin builds
# these groups from the gateway's single model listing.
rec {
  groups = [
    {
      id = "agentgateway-copilot";
      name = "AgentGateway - Copilot";
      format = "responses";
      ownedBy = "copilot";
      modelIdPrefix = "copilot/";
    }
    {
      id = "agentgateway-opencode-go";
      name = "AgentGateway - OpenCode Go (Completions)";
      format = "completions";
      ownedBy = "opencode-go/openai";
      modelIdPrefix = "opencode-go/openai/";
    }
    {
      id = "agentgateway-opencode-go-responses";
      name = "AgentGateway - OpenCode Go (Responses)";
      format = "responses";
      ownedBy = "opencode-go/openai-responses";
      modelIdPrefix = "opencode-go/openai-responses/";
    }
    {
      id = "agentgateway-opencode-go-anthropic";
      name = "AgentGateway - OpenCode Go (Anthropic)";
      format = "anthropic";
      ownedBy = "opencode-go/anthropic";
      modelIdPrefix = "opencode-go/anthropic/";
    }
    {
      id = "agentgateway-opencode-go-google";
      name = "AgentGateway - OpenCode Go (Google)";
      format = "gemini";
      ownedBy = "opencode-go/google";
      modelIdPrefix = "opencode-go/google/";
    }
    {
      id = "agentgateway-wintersteel";
      name = "AgentGateway - Wintersteel (OpenAI)";
      format = "completions";
      modelIdPrefix = "wintersteel/openai/";
    }
    # Virtual models (tiers) have bare ids, so this group is the fallback.
    {
      id = "agentgateway-virtual";
      name = "AgentGateway - Tiers";
      format = "completions";
      ownedBy = "virtual";
    }
  ];

  # Maps an alias entry to the "provider/model" string OpenCode addresses it by.
  resolve =
    lib: entry:
    if entry.provider != "agentgateway" then
      "${entry.provider}/${entry.model}"
    else
      let
        prefixed = lib.findFirst (
          g: g ? modelIdPrefix && lib.hasPrefix g.modelIdPrefix entry.model
        ) null groups;
        group = if prefixed != null then prefixed else lib.findFirst (g: !(g ? modelIdPrefix)) null groups;
      in
      "${group.id}/${
        if prefixed != null then lib.removePrefix group.modelIdPrefix entry.model else entry.model
      }";
}
