{
  config.substrate.modules.users.craig.work.vault = {
    tags = [
      "user:craig:work"
      "desktop:shells:noctalia"
      "profile:ai"
      "profile:programming"
    ];

    homeManager = {
      hdwlinux.programs = {
        herdr.vault = "kb-work";
        noctalia.vault = "kb-work";
      };
    };
  };
}
