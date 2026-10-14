{
  config.substrate.modules.ai.clients.tasks.day-plan = {
    tags = [
      "ai:clients"
      "users:craig:work"
    ];

    homeManager = {
      hdwlinux.ai.clients.tasks.day-plan = {
        description = "Morning day plan: brief actions, calendar, project work, saved items";
        schedule = "*-*-* 07:30:00";
        prompt = ./prompts/day-plan.md;
        workingDirectory = "~/Projects/kb";
      };
    };
  };
}
