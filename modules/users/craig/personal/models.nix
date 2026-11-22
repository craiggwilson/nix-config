{
  config.substrate.modules.users.craig.personal.models = {
    tags = [
      "user:craig:personal"
      "profile:ai"
    ];

    homeManager =
      { lib, ... }:
      let
        # Personal hosts route aliases through agentgateway's tier aliases
        # (llm.virtualModels in the gateway config); the failover chain lives
        # there, so each alias is a single entry that can be retargeted at the
        # gateway without touching OpenCode.
        tier = name: {
          provider = "agentgateway";
          model = name;
        };
      in
      {
        hdwlinux.ai.clients.models.aliases = lib.mkDefault {
          analysis.models = [ (tier "analysis") ];
          balanced.models = [ (tier "balanced") ];
          code-review.models = [ (tier "code-review") ];
          coding.models = [ (tier "coding") ];
          fast.models = [ (tier "fast") ];
          orchestration.models = [ (tier "orchestration") ];
          research.models = [ (tier "research") ];
          writing.models = [ (tier "writing") ];
        };
      };
  };
}
