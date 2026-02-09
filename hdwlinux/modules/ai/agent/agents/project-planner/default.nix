{
  config.substrate.modules.ai.agent.agents.project-planner = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.project-planner = {
        metadata = {
          name = "project-planner";
          description = "Expert project planner who transforms roadmap initiatives into structured project plans. Masters scope definition, resource allocation, risk planning, and stakeholder alignment to set projects up for success before execution begins.";
          tools = "Read, Write, Edit, Glob, Grep, WebFetch, WebSearch";
          model = "opus4.5";
          color = "violet";
        };
        content = ./prompt.md;
      };
    };
  };
}
