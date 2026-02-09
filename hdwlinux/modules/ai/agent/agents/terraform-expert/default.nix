{
  config.substrate.modules.ai.agent.agents.terraform-expert = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.terraform-expert = {
        description = "Expert Terraform engineer with deep knowledge of infrastructure as code, provider ecosystem, and cloud architecture. Masters module design, state management, and multi-environment deployments.";
        model = "opus4.5";
        content = ./content.md;
        extraMeta.color = "amber";
      };
    };
  };
}
