{
  config.substrate.modules.ai.agent.agents = {
    tags = [ "ai:agent" ];

    homeManager =
      { lib, ... }:
      let
        # Agent definitions without content paths (computed automatically)
        # Consolidated from 26 agents to 12 role-based agents
        agents = {
          # Core Development Agents
          coder = {
            description = "Full-stack developer for implementation tasks. Writes, tests, and refactors code across languages. Auto-loads language skills based on file context.";
            model = "coder";
            extraMeta.augment.color = "blue";
          };

          architect = {
            description = "System design, API design, database modeling, distributed systems. High-level technical decisions and architecture.";
            model = "analyst";
            extraMeta.augment.color = "violet";
          };

          code-reviewer = {
            description = "Reviews code for quality, maintainability, security, and best practices. Provides constructive feedback.";
            model = "analyst";
            extraMeta.augment.color = "orange";
          };

          debugger = {
            description = "Investigates bugs, traces issues, analyzes logs. Root cause analysis and systematic debugging.";
            model = "analyst";
            extraMeta.augment.color = "red";
          };

          # Infrastructure/Operations Agents
          platform-engineer = {
            description = "Kubernetes, Terraform, CI/CD, cloud infrastructure. Deploys and operates systems.";
            model = "coder";
            extraMeta.augment.color = "cyan";
          };

          sre = {
            description = "Observability, incident response, SLOs, reliability. Keeps systems running and improves resilience.";
            model = "analyst";
            extraMeta.augment.color = "teal";
          };

          security-engineer = {
            description = "Security reviews, threat modeling, compliance. Identifies vulnerabilities and hardens systems.";
            model = "analyst";
            extraMeta.augment.color = "red";
          };

          # Planning/Documentation Agents
          planner = {
            description = "Strategic and tactical planning. Roadmaps, project plans, task breakdowns, and sprint planning.";
            model = "writer";
            extraMeta.augment.color = "indigo";
          };

          technical-writer = {
            description = "Documentation, ADRs, tutorials, knowledge management. Clear technical communication.";
            model = "writer";
            extraMeta.augment.color = "gray";
          };

          researcher = {
            description = "Codebase analysis, technology research, competitive analysis. Investigates and reports findings.";
            model = "fast";
            extraMeta.augment.color = "teal";
          };

          # Specialized Agents
          diagram-designer = {
            description = "Visual communication designer specializing in technical diagrams, architecture visualizations, and information design.";
            model = "balanced";
            extraMeta.augment.color = "orange";
          };

          projects = {
            description = "Project management specialist for planning, tracking, and executing work using the opencode-projects-plugin.";
            mode = "primary";
            model = "writer";
            extraMeta.augment.color = "fuchsia";
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
