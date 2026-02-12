{
  config.substrate.modules.users.craig.github = {
    tags = [
      "users:craig"
      "programming"
    ];
    homeManager = {
      hdwlinux.security.secrets.entries.githubApiToken = {
        reference = "op://Craig/Github/api_token";
        mode = "0600";
      };
    };
  };
}
