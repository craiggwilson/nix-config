{
  config.substrate.modules.ai.agent.agents.mongodb-expert = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.mongodb-expert = {
        metadata = {
          name = "mongodb-expert";
          description = "Expert MongoDB and MongoDB Atlas architect with deep knowledge of database design, query optimization, replication, sharding, and cloud operations. Masters data modeling, performance tuning, and Atlas platform features.";
          tools = "Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch";
          model = "opus4.5";
          color = "green";
        };
        content = ./prompt.md;
      };
    };
  };
}
