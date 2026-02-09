{
  config.substrate.modules.ai.agent.agents.aws-expert = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.aws-expert = {
        metadata = {
          name = "aws-expert";
          description = "Expert AWS architect with deep knowledge of AWS services, well-architected framework, and cloud-native patterns. Masters compute, networking, data, security, and operational excellence on AWS.";
          tools = "Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch";
          model = "opus4.5";
          color = "orange";
        };
        content = ./prompt.md;
      };
    };
  };
}
