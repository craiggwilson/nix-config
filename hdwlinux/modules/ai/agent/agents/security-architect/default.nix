{
  config.substrate.modules.ai.agent.agents.security-architect = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.security-architect = {
        metadata = {
          name = "security-architect";
          description = "Expert security architect specializing in secure system design, threat modeling, and compliance. Masters zero-trust architecture, identity management, and security best practices across cloud-native environments.";
          tools = "Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch";
          model = "opus4.5";
          color = "red";
        };
        content = ./prompt.md;
      };
    };
  };
}
