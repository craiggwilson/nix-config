{
  config.substrate.modules.ai.clients.tasks.day-plan = {
    tags = [
      "profile:ai"
      "user:craig"
      "profile:work"
    ];

    homeManager = {
      hdwlinux.ai.clients.tasks.day-plan = {
        description = "Morning day plan: brief actions, calendar, project work, saved items";
        schedule = "*-*-* 07:00:00";
        prompt = ./prompts/day-plan.md;
        workingDirectory = "~/Projects/kb";

        # The plan consumes the brief's action items, so it must not start
        # before the brief has finished — including catch-up runs after sleep,
        # where both timers fire at once.
        after = [ "morning-brief" ];
      };
    };
  };
}
