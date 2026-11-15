{
  config.substrate.modules.ai.clients.models.agentgateway = {
    tags = [ "profile:ai" ];

    homeManager.hdwlinux.ai.clients.models.providers.agentgateway = {
      baseURL = "https://agents.wilsonfamilyhq.com/v1";
      displayName = "AgentGateway";
      # The gateway translates every client format to whatever each upstream speaks.
      formats = [
        "anthropic"
        "completions"
        "gemini"
        "responses"
      ];
    };
  };
}
