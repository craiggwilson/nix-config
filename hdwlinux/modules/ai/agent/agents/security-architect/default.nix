{
  config.substrate.modules.ai.agent.agents.security-architect = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.security-architect = {
        description = "Expert security architect specializing in secure system design, threat modeling, and compliance. Masters zero-trust architecture, identity management, and security best practices across cloud-native environments.";
        model = "reasoning";
        content = ./content.md;
        extraMeta.augment.color = "red";
      };
    };
  };
}
