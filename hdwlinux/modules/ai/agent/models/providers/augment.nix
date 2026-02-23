{
  config.substrate.modules.ai.agent.models.providers.augment = {
    tags = [
      "users:craig:work"
      "ai:agent"
    ];

    homeManager = {
      hdwlinux.ai.agent.models = {
        "Claude Haiku 4.5".providers = [ "augment" ];
        "Claude Opus 4.5".providers = [ "augment" ];
        "Claude Opus 4.6".providers = [ "augment" ];
        "Claude Sonnet 4".providers = [ "augment" ];
        "Claude Sonnet 4.5".providers = [ "augment" ];
        "Claude Sonnet 4.6".providers = [ "augment" ];
        "GPT 5".providers = [ "augment" ];
        "GPT 5.1".providers = [ "augment" ];
        "GPT 5.2".providers = [ "augment" ];
      };
    };
  };
}
