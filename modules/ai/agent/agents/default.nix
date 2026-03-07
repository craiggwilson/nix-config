{
  config.substrate.modules.ai.agent.agents = {
    tags = [ "ai:agent" ];

    homeManager =
      { config, lib, ... }:
      let
        colors = config.hdwlinux.theme.colors.withHashtag;

        # Agent definitions without content paths (computed automatically)
        # Consolidated from 26 agents to 12 role-based agents
        agents = {
          # Core Development Agents
          coder = {
            color = colors.base0D;
            description = "Full-stack developer for implementation tasks. Writes, tests, and refactors code across languages. Auto-loads language skills based on file context.";
            model = "coder";
            temperature = 0.2;
          };

          architect = {
            color = colors.base0E;
            description = "System design, API design, database modeling, distributed systems. High-level technical decisions and architecture.";
            model = "analyst";
            temperature = 0.5;
          };

          code-reviewer = {
            color = colors.base09;
            description = "Reviews code for quality, maintainability, security, and best practices. Provides constructive feedback.";
            model = "analyst";
            temperature = 0.2;
          };

          debugger = {
            color = colors.base08;
            description = "Investigates bugs, traces issues, analyzes logs. Root cause analysis and systematic debugging.";
            model = "analyst";
            temperature = 0.1;
          };

          # Infrastructure/Operations Agents
          platform-engineer = {
            color = colors.base0C;
            description = "Kubernetes, Terraform, CI/CD, cloud infrastructure. Deploys and operates systems.";
            model = "coder";
            temperature = 0.2;
          };

          sre = {
            color = colors.base0B;
            description = "Observability, incident response, SLOs, reliability. Keeps systems running and improves resilience.";
            model = "analyst";
            temperature = 0.3;
          };

          security-engineer = {
            color = colors.base08;
            description = "Security reviews, threat modeling, compliance. Identifies vulnerabilities and hardens systems.";
            model = "analyst";
            temperature = 0.2;
          };

          # Planning/Documentation Agents
          planner = {
            color = colors.base07;
            description = "Strategic and tactical planning. Roadmaps, project plans, task breakdowns, and sprint planning.";
            model = "writer";
            temperature = 0.7;
          };

          technical-writer = {
            color = colors.base04;
            description = "Documentation, ADRs, tutorials, knowledge management. Clear technical communication.";
            model = "writer";
            temperature = 0.6;
          };

          researcher = {
            color = colors.base0C;
            description = "Codebase analysis, technology research, competitive analysis. Investigates and reports findings.";
            model = "fast";
            temperature = 0.4;
          };

          # Specialized Agents
          diagram-designer = {
            color = colors.base09;
            description = "Visual communication designer specializing in technical diagrams, architecture visualizations, and information design.";
            model = "balanced";
            temperature = 0.6;
          };
        };

        # Add prompt path to each agent based on its name
        addPromptPath = name: agent: agent // { prompt = agent.prompt or (./prompts + "/${name}.md"); };
      in
      {
        hdwlinux.ai.agent.agents = lib.mapAttrs addPromptPath agents;
      };
  };
}
