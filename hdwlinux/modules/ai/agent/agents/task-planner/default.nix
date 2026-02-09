{
  config.substrate.modules.ai.agent.agents.task-planner = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.task-planner = {
        metadata = {
          name = "task-planner";
          description = "Expert task planner who decomposes project work into actionable, well-defined tasks. Masters user story creation, acceptance criteria definition, and sprint planning to enable smooth execution and predictable delivery.";
          tools = "Read, Write, Edit, Glob, Grep, WebFetch, WebSearch";
          model = "opus4.5";
          color = "purple";
        };
        content = ./prompt.md;
      };
    };
  };
}
