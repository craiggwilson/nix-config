{
  config.substrate.modules.users.craig.work.tasks.morning-brief = {
    tags = [
      "user:craig:work"
      "profile:ai"
    ];

    homeManager = {
      hdwlinux.ai.clients.tasks.morning-brief = {
        description = "Senior-staff daily brief: triage open PRs and plan the day";
        schedule = "*-*-* 07:00:00";
        prompt = ./prompts/morning-brief.md;
        workingDirectory = "~/Projects/github.com/craiggwilson/kb-work";
        timeout = "2h";
        environment.HINDSIGHT_BANK_ID = "mongodb";
      };
    };
  };
}
