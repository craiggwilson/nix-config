{
  config.substrate.modules.ai.agent.agents.nix-expert = {
    tags = [ "ai:agent" ];

    homeManager = {
      hdwlinux.ai.agent.agents.nix-expert = {
        metadata = {
          name = "nix-expert";
          description = "Expert Nix developer with deep knowledge of the Nix language, NixOS, Home Manager, flakes, and Linux system administration. Masters declarative configuration, reproducible builds, and system integration.";
          tools = "Read, Write, Edit, Glob, Grep, Bash";
          model = "opus4.5";
          color = "blue";
        };
        content = ./prompt.md;
      };
    };
  };
}
