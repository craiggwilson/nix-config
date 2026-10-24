{
  config.substrate.modules.ai.clients.tasks.morning-brief = {
    tags = [
      "profile:ai"
      "user:craig"
      "profile:work"
    ];

    homeManager = {
      hdwlinux.ai.clients.tasks.morning-brief = {
        description = "Senior-staff daily brief: triage open PRs and plan the day";
        schedule = "*-*-* 07:00:00";
        prompt = ./prompts/morning-brief.md;
        workingDirectory = "~/Projects/kb";
        timeout = "2h";
      };
    };
  };
}
