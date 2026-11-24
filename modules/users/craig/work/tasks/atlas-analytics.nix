{
  config.substrate.modules.users.craig.work.tasks.atlas-analytics = {
    tags = [
      "user:craig:work"
      "profile:ai"
    ];

    homeManager = {
      hdwlinux.ai.clients.tasks.atlas-analytics = {
        description = "Atlas Analytics: review labelled PRs and digest firebolt-* Slack into the morning brief";
        schedule = "*-*-* 07:00:00";
        prompt = ./prompts/atlas-analytics.md;
        workingDirectory = "~/Projects/github.com/craiggwilson/kb-work";
        timeout = "2h";
        environment.HINDSIGHT_BANK_ID = "mongodb";
      };
    };
  };
}
