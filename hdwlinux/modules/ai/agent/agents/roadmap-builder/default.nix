{
  config.substrate.modules.ai.agent.agents.roadmap-builder = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.roadmap-builder = {
        metadata = {
          name = "roadmap-builder";
          description = "Strategic roadmap architect who translates vision into actionable multi-quarter plans. Masters OKR alignment, dependency mapping, and stakeholder prioritization to create compelling roadmaps that balance ambition with feasibility.";
          tools = "Read, Write, Edit, Glob, Grep, WebFetch, WebSearch";
          model = "opus4.5";
          color = "indigo";
        };
        content = ./prompt.md;
      };
    };
  };
}
