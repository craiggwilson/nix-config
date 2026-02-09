{
  config.substrate.modules.ai.agent.rules.jujutsu = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.rules.jujutsu = {
        metadata = {
          description = "Version control using Jujutsu (jj)";
          type = "always_apply";
        };
        content = ./prompt.md;
      };
    };
  };
}
