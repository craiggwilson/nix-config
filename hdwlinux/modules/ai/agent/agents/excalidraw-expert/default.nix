{
  config.substrate.modules.ai.agent.agents.excalidraw-expert = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.excalidraw-expert = {
        metadata = {
          name = "excalidraw-expert";
          description = "Expert Excalidraw diagram designer specializing in creating clear, hand-drawn style technical diagrams. Masters architecture diagrams, flowcharts, sequence diagrams, and visual documentation with Excalidraw's unique aesthetic.";
          tools = "Read, Write, Edit, Glob, Grep, Bash";
          model = "opus4.5";
          color = "orange";
        };
        content = ./prompt.md;
      };
    };
  };
}
