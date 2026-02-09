{
  config.substrate.modules.ai.agent.agents.project-planner = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.project-planner = {
        description = "Expert project planner who transforms roadmap initiatives into structured project plans. Masters scope definition, resource allocation, risk planning, and stakeholder alignment to set projects up for success before execution begins.";
        model = "opus4.5";
        content = ./content.md;
        extraMeta.color = "violet";
      };
    };
  };
}
