{
  config.substrate.modules.ai.agent.agents.distributed-systems-architect = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.distributed-systems-architect = {
        metadata = {
          name = "distributed-systems-architect";
          description = "Distributed systems architect designing scalable, resilient service ecosystems. Masters service boundaries, multi-region architecture, disaster recovery, cloud-provider redundancy, and operational excellence in cloud-native environments.";
          tools = "Read, Write, Edit, Bash, Glob, Grep, WebFetch, WebSearch";
          model = "opus4.5";
          color = "yellow";
        };
        content = ./prompt.md;
      };
    };
  };
}
