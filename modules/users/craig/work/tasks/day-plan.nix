{
  config.substrate.modules.users.craig.work.tasks.day-plan = {
    tags = [
      "user:craig:work"
      "profile:ai"
    ];

    homeManager = {
      hdwlinux.ai.clients.tasks.day-plan = {
        description = "Morning day plan: brief actions, calendar, project work, saved items";
        schedule = "*-*-* 07:00:00";
        prompt = ./prompts/day-plan.md;
        workingDirectory = "~/Projects/github.com/craiggwilson/kb-work";
        environment.HINDSIGHT_BANK_ID = "mongodb";

        # The plan consumes the brief's action items, so it must not start
        # before the brief has finished — including catch-up runs after sleep,
        # where both timers fire at once.
        after = [ "morning-brief" ];
      };
    };
  };
}
