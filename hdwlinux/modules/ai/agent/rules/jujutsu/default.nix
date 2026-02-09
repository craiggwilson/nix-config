{
  config.substrate.modules.ai.agent.rules.jujutsu = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.rules.jujutsu = {
        description = "Version control using Jujutsu (jj)";
        content = ./content.md;
        extraMeta.type = "always_apply";
      };
    };
  };
}
